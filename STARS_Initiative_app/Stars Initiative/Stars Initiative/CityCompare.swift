import SwiftUI
import MapKit

// MARK: - Data Models
struct GraphSection: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
    let learnMoreDestination: String // New: identifies which detail page to show
}

struct PlantingSite: Identifiable, Hashable {
    let id = UUID()
    let address: String
    let coordinate: CLLocationCoordinate2D
    let siteType: String
    let hasWires: Bool
    let recommendedTree: String
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PlantingSite, rhs: PlantingSite) -> Bool { lhs.id == rhs.id }
}

// Global Tree Data
struct TreeData {
    static let inventory: [String: (scientific: String, score: Double, cr: Int, es: Int, ev: Int)] = {
        guard let url = Bundle.main.url(forResource: "tree_data", withExtension: "csv"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        var result: [String: (scientific: String, score: Double, cr: Int, es: Int, ev: Int)] = [:]
        let lines = contents.components(separatedBy: "\n").dropFirst()
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let fields = parseCityCSVLine(trimmed)
            guard fields.count >= 13 else { continue }
            guard let score = Double(fields[2]),
                  let cr    = Int(fields[4]),
                  let es    = Int(fields[5]),
                  let ev    = Int(fields[6]) else { continue }
            result[fields[0]] = (scientific: fields[1], score: score, cr: cr, es: es, ev: ev)
        }
        return result
    }()
}

private func parseCityCSVLine(_ line: String) -> [String] {
    var fields: [String] = []
    var current = ""
    var inQuotes = false
    for char in line {
        if char == "\"" {
            inQuotes.toggle()
        } else if char == "," && !inQuotes {
            fields.append(current)
            current = ""
        } else {
            current.append(char)
        }
    }
    fields.append(current)
    return fields
}

// MARK: - Learn More Detail View
struct LearnMoreView: View {
    let topic: String

    var pageTitle: String {
        switch topic {
        case "carbon": return "Carbon Analysis"
        case "diversity": return "Species Diversity"
        case "financial": return "Financial Efficiency"
        case "priority": return "Priority Mapping"
        default: return "Learn More"
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(pageTitle)
                        .font(.largeTitle).bold()
                        .foregroundColor(.green)
                        .padding(.bottom, 8)

                    Group {
                        switch topic {
                        case "carbon":
                            detailSection(
                                heading: "Survival-Adjusted Carbon Sequestration",
                                body: "A core innovation of the STARS model is the 'Resilience Discount'. Traditional models assume a tree sequesters a fixed amount of carbon, but in reality, a tree's carbon benefits are only realized if it survives to peak maturity. The model scales a species' environmental services score by its future climate survival probability: Effective Carbon = Base Carbon × Survival Probability."
                            )
                            detailSection(
                                heading: "Drought and Heat Stress Modelling",
                                body: "Rather than using static zones, the model runs a Sigmoid biological stress curve using future climate projections (2030 and 2050). By introducing a Thermotolerance Safety Margin (buffer of 8°F below absolute lethal limits), the model simulates Functional Stress—like stomatal closure and hydraulic cavitation—long before binary cellular death occurs."
                            )
                            detailSection(
                                heading: "Resilience Dividend Projections",
                                body: "By transitioning urban forests from vulnerable 'Climate Losers' (e.g., Coast Redwood under low-rainfall scenarios) to 'Climate Winners' (e.g., Holly Oak, Desert Willow), cities secure a major carbon dividend. In future scenarios, this prevents a projected 20% decline in forest canopy and preserves critical cooling and air purification benefits."
                            )

                        case "diversity":
                            detailSection(
                                heading: "Ecosystem Stability & Biodiverse Planting",
                                body: "Monocultures are highly vulnerable to pests and disease outbreaks. STARS enforces a dynamic genetic inventory decay model to penalize overrepresented genera, ensuring the urban forest maintains strong genetic resistance."
                            )
                            detailSection(
                                heading: "The Santamour Genus Rule",
                                body: "The model operationalizes the Santamour 10-20-30 rule (no more than 10% of one species, 20% of one genus, and 30% of one family). Using an exponential decay penalty (20 × e^(-0.15 × genus_percentage)), species belonging to over-represented genera (e.g. London Plane) are heavily penalized during overall ranking."
                            )
                            detailSection(
                                heading: "Rare-Native Rarity Multiplier",
                                body: "To encourage ecological re-wilding, the model features a Rare-Native Multiplier. Native species that currently make up a low percentage of the forest receive up to a 1.5x boost in their rarity bonus (20 × e^(-0.4 × species_percentage)), actively driving priority towards local, under-represented keystone species."
                            )

                        case "financial":
                            detailSection(
                                heading: "At-Risk Population & Liability",
                                body: "Species in Priority categories 4 and 5 represent high-risk liabilities. If a city does not proactively replace these species, it faces a massive future liability in removal and replanting costs when these trees die from heat and water stress."
                            )
                            detailSection(
                                heading: "Proactive Urban Forestry Savings",
                                body: "Switching to climate-ready species achieves up to an 80% reduction in long-term tree mortality. The STARS model projects that this proactive swap saves cities millions of dollars in cumulative removal costs by 2050, resulting in significant annual budget recovery."
                            )
                            detailSection(
                                heading: "Practical Maintenance Reduction",
                                body: "The model scores species based on maintenance traits: pruning needs, pavement damage risk, utility clearance issues, branch breakage risk, toxicity, and litter debris. Ideal low-maintenance species (Practical Score close to 100) are estimated to cost only $50/year in municipal care, compared to up to $500/year for high-burden trees."
                            )

                        case "priority":
                            detailSection(
                                heading: "Multi-Criteria Decision Analysis (MCDA)",
                                body: "STARS aggregates five key pillars to map species priority levels: Climate Resilience (35%), Effective Environmental Services (25%), Diversity Resilience (15%), Practical Considerations (15%), and Ecological Value (10%)."
                            )
                            detailSection(
                                heading: "Understanding Priority Categories",
                                body: "Species are categorized into five priority tiers based on their cumulative weighted score. Priority 1 (Score ≥ 75) indicates a 'Strategic Hero' with high survival and high benefit. Priority 2 (Score ≥ 65) represents 'Recommended' resilient choices. Priority 3 (Score ≥ 50) is 'Acceptable' with irrigation support. Priority 4 and 5 are 'Climate Risks' that should be phased out."
                            )
                            detailSection(
                                heading: "Graph Neural Network Spatial Optimization",
                                body: "Using PyTorch Geometric, the spatial pipeline builds a node-edge graph of city planting zones. By evaluating neighbor relationships, the GNN ensures that newly planted trees complement the existing canopy, maximizing overall microclimate cooling and neighborhood biodiversity without creating localized Genus bottlenecks."
                            )

                        default:
                            detailSection(heading: "STARS Engine Overview", body: "Strategic Tree-planting for Accelerated Resilience and Sustainability.")
                        }
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle(pageTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailSection(heading: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(heading)
                .font(.headline)
                .foregroundColor(.green)
            Text(body)
                .font(.body)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
        .padding(.bottom, 8)
    }
}

// MARK: - Main Selection View
struct CityCompare: View {
    private let cities = [
        ("Cupertino", "Silicon Valley"),
        ("Mountain View", "Silicon Valley"),
        ("Milpitas", "South Bay"),
        ("Sunnyvale", "Silicon Valley")
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text("Select a City")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(cities, id: \.0) { city, subtitle in
                            NavigationLink(destination: CityDetailView(cityName: city)) {
                                HStack(spacing: 16) {
                                    Image(systemName: "building.2.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                        .frame(width: 44, height: 44)
                                        .background(Color.green.opacity(0.15))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(city)
                                            .font(.title3.bold())
                                            .foregroundColor(.white)
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(white: 0.12))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Unified Detail View
struct CityDetailView: View {
    let cityName: String
    
    var coordinate: CLLocationCoordinate2D {
        switch cityName {
        case "Cupertino": return CLLocationCoordinate2D(latitude: 37.3230, longitude: -122.0322)
        case "Mountain View": return CLLocationCoordinate2D(latitude: 37.3861, longitude: -122.0839)
        case "Milpitas": return CLLocationCoordinate2D(latitude: 37.4323, longitude: -121.8996)
        case "Sunnyvale": return CLLocationCoordinate2D(latitude: 37.3688, longitude: -122.0363)
        default: return CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863)
        }
    }
    
    var graphs: [GraphSection] {
        let prefix: String
        switch cityName {
        case "Mountain View": prefix = "MtView"
        case "Milpitas": prefix = "Milpitas"
        case "Sunnyvale": prefix = "Sunnyvale"
        default: prefix = "Cupertino"
        }
        
        return [
            GraphSection(imageName: "\(prefix)_carbon_analysis", title: "Carbon Analysis", description: "STARS optimization reduces carbon footprint by sequestering more amounts of carbon than the current urban forest accomplishes.", learnMoreDestination: "carbon"),
            GraphSection(imageName: "\(prefix)_diversity_graph", title: "Species Diversity", description: "STARS shapes urban forests by transitioning from low to high biodiversity where STARS regularly enforces the Santamour Genus Rule.", learnMoreDestination: "diversity"),
            GraphSection(imageName: "\(prefix)_money_graph", title: "Financial Efficiency", description: "Comparisons of the estimated future replanting costs for the current and STARS-optimized urban forest.", learnMoreDestination: "financial"),
            GraphSection(imageName: "\(prefix)_priority_shift", title: "Priority Mapping", description: "Graph representing the STARS priority distribution for the current urban forest to the future simulated STARS one.", learnMoreDestination: "priority")
        ]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Static city map header (no interactive buttons)
                    Map(initialPosition: .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04))), interactionModes: [])
                        .frame(height: 180)
                        .overlay(alignment: .bottomLeading) {
                            Text(cityName)
                                .font(.title2).bold()
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding()
                        }

                    // MARK: Action Buttons
                    VStack(spacing: 12) {
                        // Planting Zones button (replaces old Map + List buttons)
                        NavigationLink(destination: PlantingZoneModeView(cityName: cityName)) {
                            Label("Available Planting Zones", systemImage: "mappin.and.ellipse")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.1, green: 0.6, blue: 0.3))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        NavigationLink(destination: GNNSpatialImpactView(cityName: cityName)) {
                            Label("View Spatial Impact Map", systemImage: "map.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        NavigationLink(destination: RLHomeLandingView(cityName: cityName)) {
                            Label("RL Optimizer", systemImage: "brain.head.profile")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 30)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("STARS Optimization Report")
                            .font(.title2).bold()
                            .foregroundColor(.white)
                            .padding(.top)

                        ForEach(graphs) { graph in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(graph.title)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Image(graph.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 5)

                                Text(graph.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                NavigationLink(destination: LearnMoreView(topic: graph.learnMoreDestination)) {
                                    Text("Learn more →")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .background(Color(white: 0.12))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                }
            }
            .edgesIgnoringSafeArea(.top)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Planting Zone Mode Selection
struct PlantingZoneModeView: View {
    let cityName: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                VStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 52))
                        .foregroundColor(.green)
                    Text("Planting Zones")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(cityName)
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)

                VStack(spacing: 16) {
                    NavigationLink(destination: PlantingMapView(cityName: cityName, showMap: true)) {
                        HStack(spacing: 20) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Map View")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Text("See all planting sites plotted on an interactive map")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                        .padding(20)
                        .background(Color(white: 0.12))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: PlantingZonesView(cityName: cityName)) {
                        HStack(spacing: 20) {
                            Image(systemName: "list.bullet.rectangle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.cyan)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("List View")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Text("Browse all STARS-recommended zones sorted by address")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                        .padding(20)
                        .background(Color(white: 0.12))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Available Zones")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Planting Zones View (card list of STARS-recommended sites)
struct PlantingZonesView: View {
    let cityName: String

    @State private var sites: [PlantingSite] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                ProgressView("Loading zones…")
                    .foregroundColor(.green)
                    .tint(.green)
            } else if sites.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green.opacity(0.5))
                    Text("No zone data available for \(cityName).")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sites) { site in
                            NavigationLink(destination: TreeLocationDetailView(site: site)) {
                                HStack(spacing: 16) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(site.recommendedTree)
                                            .font(.system(.body, design: .rounded)).bold()
                                            .foregroundColor(.white)
                                        Text(site.address)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        HStack(spacing: 8) {
                                            Label(site.siteType, systemImage: "location.fill")
                                                .font(.caption2)
                                                .foregroundColor(.green.opacity(0.8))
                                            if site.hasWires {
                                                Label("Wires", systemImage: "exclamationmark.triangle.fill")
                                                    .font(.caption2)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(white: 0.12))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Planting Zones – \(cityName)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadZones()
            isLoading = false
        }
    }

    private func loadZones() async {
        let fileName: String
        switch cityName {
        case "Cupertino": fileName = "Cupertino_Smart_Zones"
        case "Mountain View": fileName = "MtView_Smart_Zones"
        case "Milpitas": fileName = "Milpitas_Smart_Zones"
        case "Sunnyvale": fileName = "Sunnyvale_Smart_Zones"
        default: fileName = ""
        }
        guard !fileName.isEmpty, let path = Bundle.main.path(forResource: fileName, ofType: "csv") else { return }
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            var loaded: [PlantingSite] = []
            let header = rows[0].components(separatedBy: ",")
            let addrIdx = header.firstIndex(of: "address") ?? 0
            let latIdx  = header.firstIndex(of: "latitude") ?? 1
            let lonIdx  = header.firstIndex(of: "longitude") ?? 2
            let typeIdx = header.firstIndex(of: "site_type") ?? 3
            let wireIdx = header.firstIndex(of: "has_wires") ?? 4
            let treeIdx = header.firstIndex(of: "recommended_tree") ?? 5
            for row in rows.dropFirst() {
                let cols = row.components(separatedBy: ",")
                if cols.count >= 6 {
                    let lat = Double(cols[latIdx].trimmingCharacters(in: .whitespaces)) ?? 0
                    let lon = Double(cols[lonIdx].trimmingCharacters(in: .whitespaces)) ?? 0
                    if lat != 0 {
                        loaded.append(PlantingSite(
                            address: cols[addrIdx],
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                            siteType: cols[typeIdx],
                            hasWires: cols[wireIdx].lowercased().contains("true") || cols[wireIdx].lowercased() == "y",
                            recommendedTree: cols[treeIdx]
                        ))
                    }
                }
            }
            self.sites = loaded
        } catch { print("PlantingZonesView error: \(error)") }
    }
}

// MARK: - Optimized Planting Map/List View (legacy – kept for internal use)
struct PlantingMapView: View {
    let cityName: String
    let showMap: Bool

    @State private var sites: [PlantingSite] = []
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedSite: PlantingSite?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Group {
                if showMap {
                    Map(position: $position, selection: $selectedSite) {
                        ForEach(sites) { site in
                            Marker(site.recommendedTree, systemImage: "tree.fill", coordinate: site.coordinate)
                                .tag(site)
                                .tint(.green)
                        }
                    }
                    .navigationDestination(item: $selectedSite) { site in
                        TreeLocationDetailView(site: site)
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("Recommended Trees for \(cityName)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding([.leading, .top])
                        
                        List(sites) { site in
                            NavigationLink(destination: TreeLocationDetailView(site: site)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(site.recommendedTree)
                                            .font(.system(.body, design: .rounded)).bold()
                                            .foregroundColor(.white)
                                        Text(site.address)
                                            .font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color(white: 0.12))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle(showMap ? "Planting Map" : "Planting List")
        .task {
            await loadCSVData()
            setupInitialCamera()
        }
    }
    
    private func setupInitialCamera() {
        let center: CLLocationCoordinate2D
        switch cityName {
        case "Cupertino": center = CLLocationCoordinate2D(latitude: 37.3230, longitude: -122.0322)
        case "Mountain View": center = CLLocationCoordinate2D(latitude: 37.3861, longitude: -122.0839)
        case "Milpitas": center = CLLocationCoordinate2D(latitude: 37.4323, longitude: -121.8996)
        case "Sunnyvale": center = CLLocationCoordinate2D(latitude: 37.3688, longitude: -122.0363)
        default: center = CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863)
        }
        position = .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
    }
    
    private func loadCSVData() async {
        let fileName: String
        switch cityName {
        case "Cupertino": fileName = "Cupertino_Smart_Zones"
        case "Mountain View": fileName = "MtView_Smart_Zones"
        case "Milpitas": fileName = "Milpitas_Smart_Zones"
        case "Sunnyvale": fileName = "Sunnyvale_Smart_Zones"
        default: fileName = ""
        }
        
        guard !fileName.isEmpty, let path = Bundle.main.path(forResource: fileName, ofType: "csv") else { return }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            var loadedSites: [PlantingSite] = []
            let header = rows[0].components(separatedBy: ",")
            
            let addrIdx = header.firstIndex(of: "address") ?? 0
            let latIdx = header.firstIndex(of: "latitude") ?? 1
            let lonIdx = header.firstIndex(of: "longitude") ?? 2
            let typeIdx = header.firstIndex(of: "site_type") ?? 3
            let wireIdx = header.firstIndex(of: "has_wires") ?? 4
            let treeIdx = header.firstIndex(of: "recommended_tree") ?? 5

            for row in rows.dropFirst() {
                let cols = row.components(separatedBy: ",")
                if cols.count >= 6 {
                    let latVal = Double(cols[latIdx].trimmingCharacters(in: .whitespaces)) ?? 0.0
                    let lonVal = Double(cols[lonIdx].trimmingCharacters(in: .whitespaces)) ?? 0.0
                    if latVal != 0.0 {
                        loadedSites.append(PlantingSite(
                            address: cols[addrIdx],
                            coordinate: CLLocationCoordinate2D(latitude: latVal, longitude: lonVal),
                            siteType: cols[typeIdx],
                            hasWires: cols[wireIdx].lowercased().contains("true") || cols[wireIdx].lowercased() == "y",
                            recommendedTree: cols[treeIdx]
                        ))
                    }
                }
            }
            self.sites = loadedSites
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Tree Location Detail View (3D rotating map + bottom info panel)
struct TreeLocationDetailView: View {
    let site: PlantingSite

    @State private var heading: Double = 0
    @State private var cameraPosition: MapCameraPosition

    private let rotationTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    init(site: PlantingSite) {
        self.site = site
        _cameraPosition = State(initialValue: .camera(MapCamera(
            centerCoordinate: site.coordinate,
            distance: 600,
            heading: 0,
            pitch: 65
        )))
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── 3-D rotating map ──────────────────────────────────────
            Map(position: $cameraPosition) {
                // Glowing planting-zone circle on the ground
                MapCircle(center: site.coordinate, radius: 4)
                    .foregroundStyle(Color.green.opacity(0.30))
                    .stroke(.green, lineWidth: 1.5)

                // Custom tree marker
                Annotation(site.recommendedTree, coordinate: site.coordinate) {
                    VStack(spacing: 2) {
                        Image(systemName: "tree.fill")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(color: .green.opacity(0.6), radius: 4)
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.green)
                            .offset(y: -3)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .ignoresSafeArea()
            .onReceive(rotationTimer) { _ in
                heading += 0.30
                if heading >= 360 { heading = 0 }
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: site.coordinate,
                    distance: 600,
                    heading: heading,
                    pitch: 65
                ))
            }

            // ── Bottom info panel ─────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {

                // Drag handle
                HStack {
                    Spacer()
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 40, height: 4)
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.bottom, 14)

                // Badge
                Text("STARS RECOMMENDATION")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(.green)
                    .padding(.bottom, 2)

                // Tree name
                Text(site.recommendedTree)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                if let details = TreeData.inventory[site.recommendedTree] {
                    Text(details.scientific)
                        .font(.subheadline).italic()
                        .foregroundColor(.gray)
                        .padding(.bottom, 12)

                    // Score chips row
                    HStack(spacing: 10) {
                        ScoreChip(label: "Climate",     value: details.cr, color: .cyan)
                        ScoreChip(label: "Eco-Service", value: details.es, color: .green)
                        ScoreChip(label: "Ecology",     value: details.ev, color: .mint)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(String(format: "%.1f", details.score))
                                .font(.title2.bold())
                                .foregroundColor(.green)
                            Text("Overall")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 14)
                }

                Divider().background(Color.white.opacity(0.1)).padding(.bottom, 10)

                // Site meta-data row
                HStack(spacing: 12) {
                    Label(site.address, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Label(site.siteType, systemImage: "square.split.2x1.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    if site.hasWires {
                        Label("Wires", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Score Chip
struct ScoreChip: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline.bold())
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
}

// MARK: - Score View (kept for compatibility)
struct ScoreView: View {
    let label: String
    let score: Int
    var body: some View {
        VStack {
            Text("\(score)").font(.title3.bold()).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.green)
        }
    }
}

#Preview {
    CityCompare()
}
