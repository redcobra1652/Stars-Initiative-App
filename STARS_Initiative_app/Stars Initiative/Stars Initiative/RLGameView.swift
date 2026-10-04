import SwiftUI

// MARK: - Year Phase

enum YearPhase {
    case acting   // player is spending this year's budget
    case recap    // year just ended — show player vs. RL comparison
    case finished // all simYears complete — show final results
}

struct YearActionLogEntry: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let isWarning: Bool
}

struct YearRecap {
    let yearNumber: Int
    let actions: [String]
    let starsScore: Double
    let canopyPct: Double
    let biodiversity: Double
    let budgetSpent: Double
    let rlYear: RLBenchmarkYear?
}

enum ActionMode: Equatable {
    case none
    case plantPickSpecies
    case plantEnterCount(species: String)
    case swapPickFrom
    case swapPickTo(from: String)
    case swapEnterCount(from: String, to: String)
}

// MARK: - Game Engine
// Built around the actual exported schema: swapBatches are the model's own
// curated list of at-risk species (already scored/prioritized), scoreTable
// covers every candidate species you could swap into, and the win
// condition is a single population-weighted STARS score compared against
// winConditions.aiScore — matching how the notebook scores both sides.
final class RLGameEngine: ObservableObject {
    let config: RLGameConfig
    let cfg: RLCityConfig

    @Published var inventory: [String: Double] // species key -> count
    @Published var year: Int = 0
    @Published var budgetRemaining: Double = 0
    @Published var maintenanceCostThisYear: Double = 0
    @Published var actionsThisYear: [YearActionLogEntry] = []
    @Published var phase: YearPhase = .acting
    @Published var recap: YearRecap?

    init(config: RLGameConfig) {
        self.config = config
        self.cfg = config.cityConfig
        self.inventory = config.startingInventory
        startYear()
    }

    // MARK: Derived state

    var yearFraction: Double { Double(year) / Double(max(cfg.simYears, 1)) }
    var totalTrees: Double { inventory.values.reduce(0, +) }
    var canopyPct: Double { min(100.0, totalTrees * 28 / 1_000_000 * 100) }
    var annualBudget: Double { cfg.annualBudget }

    var budgetSpentThisYear: Double {
        max(0, (cfg.annualBudget - maintenanceCostThisYear) - budgetRemaining)
    }

    var biodiversity: Double {
        let counts = inventory.values.filter { $0 > 0 }
        let total = counts.reduce(0, +)
        guard total > 0 else { return 0 }
        let probs = counts.map { $0 / total }
        return -probs.reduce(0.0) { $0 + $1 * log($1 + 1e-12) }
    }

    /// Population-weighted STARS score — same metric winConditions.aiScore
    /// is measured in, so the final comparison is apples-to-apples.
    var starsScore: Double {
        var weighted = 0.0
        var total = 0.0
        for (name, count) in inventory where count > 0 {
            let score = config.scoreTable[name] ?? 50.0
            weighted += score * count
            total += count
        }
        return total > 0 ? weighted / total : 0
    }

    func speciesShare(_ key: String) -> Double {
        guard totalTrees > 0 else { return 0 }
        return (inventory[key] ?? 0) / totalTrees
    }

    // The export no longer includes a per-species climate-resilience
    // breakdown (only the composite overall score), so survival is
    // approximated from that composite score in place of a dedicated
    // resilience figure.
    private func climateSurvival(forScore score: Double) -> Double {
        let curTemp = cfg.climate.currentTempF + (cfg.climate.temp2050F - cfg.climate.currentTempF) * yearFraction
        let curRain = cfg.climate.currentRainfallIn - (cfg.climate.currentRainfallIn - cfg.climate.rainfall2050In) * yearFraction
        let tSt = max(0.0, curTemp - 78.0)
        let dSt = max(0.0, 14.0 - curRain)
        return (100.0 / 100.0) * exp(-0.04 * tSt - 0.08 * dSt)
    }

    // MARK: Year lifecycle

    private func startYear() {
        maintenanceCostThisYear = cfg.costMaintenance * totalTrees * (1 + cfg.overheadPct) * 0.3
        budgetRemaining = max(0, cfg.annualBudget - maintenanceCostThisYear)
        actionsThisYear = []
        phase = .acting
    }

    func endYear() {
        guard phase == .acting else { return }
        let attrition = 0.01 + 0.005 * yearFraction
        for key in inventory.keys {
            inventory[key] = max(0, (inventory[key] ?? 0) * (1 - attrition))
        }

        let spent = budgetSpentThisYear
        let completedYear = year + 1
        let rl = config.rlBenchmark.first(where: { $0.year == completedYear })

        recap = YearRecap(
            yearNumber: completedYear,
            actions: actionsThisYear.filter { !$0.isWarning }.map { $0.text },
            starsScore: starsScore,
            canopyPct: canopyPct,
            biodiversity: biodiversity,
            budgetSpent: spent,
            rlYear: rl
        )
        year = completedYear
        phase = .recap
    }

    func continueAfterRecap() {
        if year >= cfg.simYears {
            phase = .finished
        } else {
            startYear()
        }
    }

    // MARK: Actions

    /// Plant New: add brand-new trees of a species (works for species not
    /// currently in inventory too — e.g. filling vacant sites with
    /// something new from scoreTable).
    func plantNew(species: String, requestedCount: Double) {
        guard phase == .acting else { return }
        guard requestedCount >= 1 else {
            actionsThisYear.append(.init(text: "❌ Enter a valid number of trees to plant.", isWarning: true))
            return
        }
        let count = requestedCount
        let current = inventory[species] ?? 0
        let projectedShare = (current + count) / max(totalTrees + count, 1e-9)
        guard projectedShare <= 0.10 else {
            actionsThisYear.append(.init(text: "❌ \(species.capitalized) would exceed its 10% diversity cap.", isWarning: true))
            return
        }
        let cost = count * (cfg.costPlant * (1 + cfg.overheadPct) + cfg.costWater3yr)
        guard cost <= budgetRemaining else {
            actionsThisYear.append(.init(text: "❌ Not enough budget to plant \(Int(count)) \(species.capitalized) — needs $\(Int(cost)), you have $\(Int(budgetRemaining)) left.", isWarning: true))
            return
        }
        budgetRemaining -= cost

        let score = config.scoreTable[species] ?? 50.0
        let survival = climateSurvival(forScore: score)
        let nSurvive = count * survival
        let nFail = count - nSurvive
        inventory[species] = current + nSurvive

        actionsThisYear.append(.init(
            text: "🌱 Planted \(Int(count)) \(species.capitalized) — \(Int(nSurvive.rounded())) survived, \(Int(nFail.rounded())) lost to climate stress.",
            isWarning: false))
    }

    /// Strategic Swap — cost follows the notebook's documented
    /// swapCostFormula exactly: n * (removal*(1+overhead) + plant*(1+overhead) + water3yr)
    func swap(from: String, to: String, requestedCount: Double) {
        guard phase == .acting else { return }
        let available = inventory[from] ?? 0
        let count = min(max(requestedCount, 0), available)

        guard count >= 1 else {
            actionsThisYear.append(.init(text: "❌ Enter a valid number of \(from.capitalized) to swap — you have \(Int(available)) available.", isWarning: true))
            return
        }
        let currentTo = inventory[to] ?? 0
        let projectedToShare = (currentTo + count) / max(totalTrees, 1e-9)
        guard projectedToShare <= 0.10 else {
            actionsThisYear.append(.init(text: "❌ Swapping into \(to.capitalized) would exceed its 10% diversity cap.", isWarning: true))
            return
        }

        let cost = count * (cfg.costRemoval * (1 + cfg.overheadPct) + cfg.costPlant * (1 + cfg.overheadPct) + cfg.costWater3yr)
        guard cost <= budgetRemaining else {
            actionsThisYear.append(.init(text: "❌ Not enough budget to swap \(Int(count)) \(from.capitalized) → \(to.capitalized) — needs $\(Int(cost)).", isWarning: true))
            return
        }
        budgetRemaining -= cost
        inventory[from] = available - count

        let score = config.scoreTable[to] ?? 50.0
        let survival = climateSurvival(forScore: score)
        let nSurvive = count * survival
        let nFail = count - nSurvive
        inventory[to] = currentTo + nSurvive

        actionsThisYear.append(.init(
            text: "🔄 Swapped \(Int(count)) \(from.capitalized) → \(to.capitalized) — \(Int(nSurvive.rounded())) established, \(Int(nFail.rounded())) didn't take.",
            isWarning: false))
    }
}

// MARK: - Entry point (loads config for the current city)

struct RLGameView: View {
    let cityName: String
    @State private var config: RLGameConfig?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let config = config {
                RLGamePlayView(config: config)
            } else if loadFailed {
                Text("Couldn't load the RL game for \(cityName).\nMake sure \(CityAssets.filePrefix(for: cityName))_rl_game_config.json is in the app bundle.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ProgressView("Loading game…")
            }
        }
        .navigationTitle("Beat the RL Agent")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let loaded = RLGameLoader.load(forCity: cityName) {
                config = loaded
            } else {
                loadFailed = true
            }
        }
    }
}

// MARK: - Top-level gameplay switcher

struct RLGamePlayView: View {
    @StateObject private var engine: RLGameEngine
    let config: RLGameConfig

    init(config: RLGameConfig) {
        self.config = config
        _engine = StateObject(wrappedValue: RLGameEngine(config: config))
    }

    var body: some View {
        switch engine.phase {
        case .acting:
            ActingYearView(engine: engine, config: config)
        case .recap:
            if let recap = engine.recap {
                YearRecapView(recap: recap, engine: engine)
            } else {
                ProgressView()
            }
        case .finished:
            RLResultsView(engine: engine, config: config)
        }
    }
}

// MARK: - Acting phase (spend the year's budget)

struct ActingYearView: View {
    @ObservedObject var engine: RLGameEngine
    let config: RLGameConfig
    @State private var actionMode: ActionMode = .none
    @State private var countText: String = ""
    @State private var showInfo = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            budgetBar
            Divider().padding(.bottom, 4)

            Group {
                switch actionMode {
                case .none:
                    actionMenu
                case .plantPickSpecies:
                    plantSpeciesPicker
                case .plantEnterCount(let species):
                    plantCountEntry(species: species)
                case .swapPickFrom:
                    fromBatchPicker
                case .swapPickTo(let from):
                    toSpeciesPicker(from: from)
                case .swapEnterCount(let from, let to):
                    swapCountEntry(from: from, to: to)
                }
            }
            .frame(maxHeight: 300)

            if !engine.actionsThisYear.isEmpty {
                Divider().padding(.top, 4)
                actionsLog
            }

            Spacer(minLength: 8)

            Button {
                engine.endYear()
            } label: {
                Text("End Year →")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showInfo = true } label: { Image(systemName: "info.circle") }
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoSheetView(config: config)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Year \(engine.year + 1) of \(config.cityConfig.simYears)")
                .font(.title3.bold())
            HStack(spacing: 20) {
                statPill("STARS", String(format: "%.1f", engine.starsScore))
                statPill("Trees", "\(Int(engine.totalTrees))")
                statPill("Canopy", "\(String(format: "%.1f", engine.canopyPct))%")
            }
        }
        .padding(.top, 10)
    }

    private var budgetBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Annual Budget: $\(Int(engine.annualBudget))")
                    .font(.caption).foregroundColor(.gray)
                Spacer()
                Text("Remaining: $\(Int(engine.budgetRemaining))")
                    .font(.caption.bold()).foregroundColor(.green)
            }
            ProgressView(value: engine.budgetRemaining, total: max(engine.annualBudget - engine.maintenanceCostThisYear, 1))
                .tint(.green)
            Text("Maintenance on existing trees already cost $\(Int(engine.maintenanceCostThisYear)) this year.")
                .font(.caption2).foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }

    private var actionMenu: some View {
        VStack(spacing: 10) {
            Button {
                actionMode = .plantPickSpecies
            } label: {
                Label("Plant New (Fill Vacant Sites)", systemImage: "leaf.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(white: 0.15))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button {
                actionMode = .swapPickFrom
            } label: {
                Label("Strategic Swap (Replace At-Risk Species)", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(white: 0.15))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Text("Or just tap “End Year” below if you'd rather not plant anything this year.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: Plant New flow

    private var plantSpeciesPicker: some View {
        VStack(spacing: 0) {
            pickerHeader(title: "Plant which species? (strongest scores first)")
            let candidates = config.scoreTable
                .sorted { $0.value > $1.value }
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(candidates, id: \.key) { key, score in
                        Button {
                            countText = ""
                            actionMode = .plantEnterCount(species: key)
                        } label: {
                            HStack {
                                Text(key.capitalized).foregroundColor(.white)
                                Spacer()
                                Text("Score \(Int(score))").font(.caption).foregroundColor(.green)
                            }
                            .padding()
                            .background(Color(white: 0.15))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func plantCountEntry(species: String) -> some View {
        VStack(spacing: 14) {
            pickerHeader(title: "Plant \(species.capitalized)")
            Text("How many new trees would you like to plant?")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Number of trees", text: $countText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button {
                let count = Double(countText) ?? 0
                engine.plantNew(species: species, requestedCount: count)
                countText = ""
                actionMode = .none
            } label: {
                Text("Confirm Planting")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .onAppear { countText = "50" }
    }

    // MARK: Strategic Swap flow

    // Step 1: which at-risk batch to start replacing. These come straight
    // from the model's own curated swapBatches list, weakest score first.
    private var fromBatchPicker: some View {
        VStack(spacing: 0) {
            pickerHeader(title: "Which species would you like to replace? (weakest scores first)")
            let sorted = config.swapBatches.sorted { $0.currentScore < $1.currentScore }
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(sorted) { batch in
                        Button {
                            actionMode = .swapPickTo(from: batch.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(batch.speciesName).foregroundColor(.white)
                                    Text("\(batch.priorityLevel) • \(Int(engine.inventory[batch.id] ?? 0)) planted")
                                        .font(.caption2).foregroundColor(.gray)
                                }
                                Spacer()
                                Text("Score \(String(format: "%.1f", batch.currentScore))")
                                    .font(.caption).foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color(white: 0.15))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // Step 2: what replaces it. Full candidate pool, strongest score first.
    private func toSpeciesPicker(from: String) -> some View {
        VStack(spacing: 0) {
            pickerHeader(title: "Replace it with which species? (strongest scores first)")
            let candidates = config.scoreTable
                .filter { $0.key != from }
                .sorted { $0.value > $1.value }
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(candidates, id: \.key) { key, score in
                        Button {
                            countText = ""
                            actionMode = .swapEnterCount(from: from, to: key)
                        } label: {
                            HStack {
                                Text(key.capitalized).foregroundColor(.white)
                                Spacer()
                                Text("Score \(Int(score))").font(.caption).foregroundColor(.green)
                            }
                            .padding()
                            .background(Color(white: 0.15))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // Step 3: how many trees to swap.
    private func swapCountEntry(from: String, to: String) -> some View {
        let available = engine.inventory[from] ?? 0
        let suggested = Int((available * config.cityConfig.replacementRate).rounded())

        return VStack(spacing: 14) {
            pickerHeader(title: "\(from.capitalized) → \(to.capitalized)")

            Text("You have \(Int(available)) \(from.capitalized) planted. The model's own strategy replaces about \(Int(config.cityConfig.replacementRate * 100))% (\(suggested)) at a time, but you choose the amount.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Number of trees to replace", text: $countText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button {
                let count = Double(countText) ?? 0
                engine.swap(from: from, to: to, requestedCount: count)
                countText = ""
                actionMode = .none
            } label: {
                Text("Confirm Swap")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .onAppear { countText = String(suggested) }
    }

    private func pickerHeader(title: String) -> some View {
        HStack {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Button("Cancel") { actionMode = .none }
                .font(.caption)
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
    }

    private var actionsLog: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(engine.actionsThisYear) { entry in
                    Text(entry.text)
                        .font(.caption)
                        .foregroundColor(entry.isWarning ? .red : .secondary)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 90)
    }

    private func statPill(_ label: String, _ value: String) -> some View {
        VStack {
            Text(value).font(.headline).foregroundColor(.green)
            Text(label).font(.caption2).foregroundColor(.gray)
        }
    }
}

// MARK: - Info sheet (surfaces the model's own instructions/tips)

struct InfoSheetView: View {
    let config: RLGameConfig
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(config.winConditions.description)
                        .font(.headline)
                        .foregroundColor(.green)
                    Text(config.winConditions.metric)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Instructions").font(.headline).padding(.top, 8)
                    ForEach(config.instructions, id: \.self) { line in
                        Text("• \(line)").font(.subheadline)
                    }

                    Text("Tips").font(.headline).padding(.top, 8)
                    ForEach(config.tips, id: \.self) { line in
                        Text("• \(line)").font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Recap phase (compare this year's moves to the RL agent's)

struct YearRecapView: View {
    let recap: YearRecap
    @ObservedObject var engine: RLGameEngine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Year \(recap.yearNumber) Recap")
                    .font(.title2.bold())
                    .foregroundColor(.green)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Moves").font(.headline).foregroundColor(.blue)
                    if recap.actions.isEmpty {
                        Text("You left the forest unchanged this year.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(recap.actions, id: \.self) { a in
                            Text(a).font(.subheadline)
                        }
                    }
                    Text("Spent $\(Int(recap.budgetSpent)) of $\(Int(engine.annualBudget)) budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.1))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("RL Agent's Move").font(.headline).foregroundColor(.purple)
                    if let rl = recap.rlYear {
                        Text(rl.action.capitalized).font(.subheadline)
                        Text("STARS Score: \(String(format: "%.2f", rl.starsScore))  •  \(String(format: "%.1f", rl.pctDone))% through its plan")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No RL data for this year.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.1))
                .cornerRadius(12)

                HStack(spacing: 24) {
                    statCompare("STARS Score", recap.starsScore, recap.rlYear?.starsScore, decimals: 1)
                    statCompare("Canopy", recap.canopyPct, nil, suffix: "%")
                    statCompare("Biodiv", recap.biodiversity, nil, decimals: 2)
                }
                .frame(maxWidth: .infinity)

                Button {
                    engine.continueAfterRecap()
                } label: {
                    Text(engine.year >= engine.cfg.simYears ? "See Final Results →" : "Continue to Year \(engine.year + 1) →")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }

    private func statCompare(_ label: String, _ user: Double, _ rl: Double?, suffix: String = "", decimals: Int = 0) -> some View {
        let numFmt = "%.\(decimals)f"
        return VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundColor(.gray)
            Text("\(String(format: numFmt, user))\(suffix)").font(.subheadline.bold()).foregroundColor(.blue)
            if let rl = rl {
                Text("\(String(format: numFmt, rl))\(suffix)").font(.caption).foregroundColor(.purple)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Final results

struct RLResultsView: View {
    @ObservedObject var engine: RLGameEngine
    let config: RLGameConfig

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("25 Years Complete")
                    .font(.largeTitle.bold())
                    .foregroundColor(.green)
                    .padding(.top)

                resultRow("STARS Score", user: engine.starsScore, rl: config.winConditions.aiScore, decimals: 2)

                let userWon = engine.starsScore > config.winConditions.aiScore

                Text(userWon
                     ? "🌳 You beat the AI's STARS score!"
                     : "🤖 The AI's 25-year strategy edged you out this time.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(white: 0.12))
                    .cornerRadius(12)
                    .padding(.horizontal)

                VStack(spacing: 10) {
                    Text("Other Final Stats").font(.subheadline).foregroundColor(.gray)
                    HStack(spacing: 30) {
                        VStack { Text("\(Int(engine.totalTrees))").font(.headline).foregroundColor(.white); Text("Trees").font(.caption2).foregroundColor(.gray) }
                        VStack { Text("\(String(format: "%.1f", engine.canopyPct))%").font(.headline).foregroundColor(.white); Text("Canopy").font(.caption2).foregroundColor(.gray) }
                        VStack { Text("\(String(format: "%.2f", engine.biodiversity))").font(.headline).foregroundColor(.white); Text("Biodiversity").font(.caption2).foregroundColor(.gray) }
                    }
                }
                .padding(.top, 4)

                Text(config.winConditions.metric)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private func resultRow(_ label: String, user: Double, rl: Double, suffix: String = "", decimals: Int = 0) -> some View {
        let numFmt = "%.\(decimals)f"
        return VStack(spacing: 6) {
            Text(label).font(.subheadline).foregroundColor(.gray)
            HStack(spacing: 30) {
                VStack {
                    Text("\(String(format: numFmt, user))\(suffix)").font(.title2.bold()).foregroundColor(.white)
                    Text("You").font(.caption2).foregroundColor(.blue)
                }
                Text("vs").foregroundColor(.gray)
                VStack {
                    Text("\(String(format: numFmt, rl))\(suffix)").font(.title2.bold()).foregroundColor(.white)
                    Text("AI").font(.caption2).foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
