import SwiftUI
import MapKit

// MARK: - Score metric selection

enum ScoreMetric: String, CaseIterable, Identifiable {
    case overall
    case shade
    case diversity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .overall:    return "Overall"
        case .shade:      return "Shade"
        case .diversity:  return "Diversity"
        }
    }
}

// A coarse geographic bucket used to render a smooth gradient instead of
// thousands of individual per-site shapes. Each cell's coordinate is the
// centroid of the sites that fell into it, and its score is their average
// for whichever metric is currently selected.
struct ScoreGridCell: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let avgScore: Double
    let radiusMeters: Double
}

struct GNNSpatialImpactView: View {
    let cityName: String

    @State private var impact: GNNImpactExport?
    @State private var selectedMetric: ScoreMetric = .overall
    @State private var showAfter = true
    @State private var position: MapCameraPosition = .automatic

    // Grids are cached per (metric, before/after) combo so flipping between
    // tabs you've already visited is instant instead of re-bucketing sites
    // every time.
    @State private var gridCache: [String: [ScoreGridCell]] = [:]
    @State private var currentCells: [ScoreGridCell] = []
    @State private var isBuildingGrid = false

    var body: some View {
        Group {
            if let impact = impact {
                VStack(spacing: 0) {
                    // Metric tabs -- overall / shade / diversity / resilience
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(ScoreMetric.allCases) { metric in
                            Text(metric.label).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding([.horizontal, .top])

                    Picker("View", selection: $showAfter) {
                        Text("Before").tag(false)
                        Text("After (GNN)").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    // MapCircle is a native MapKit overlay rendered by the
                    // map's own Metal-backed renderer -- not a per-shape
                    // SwiftUI view like Annotation -- so a few hundred of
                    // these stay smooth where thousands of Annotations did
                    // not. Overlapping, semi-transparent circles blend into
                    // a soft gradient instead of a grid of hard dots.
                    ZStack {
                        Map(position: $position, interactionModes: [.pan, .zoom]) {
                            ForEach(currentCells) { cell in
                                MapCircle(center: cell.coordinate, radius: cell.radiusMeters)
                                    .foregroundStyle(colorForScore(cell.avgScore).opacity(0.55))
                                    .stroke(.clear)
                            }
                        }

                        if isBuildingGrid {
                            ProgressView()
                                .padding(10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .frame(height: 340)

                    ScrollView {
                        statsCard(for: impact.summary, metric: selectedMetric)
                            .padding()
                    }
                }
            } else {
                GNNLoadingView(cityName: cityName)
            }
        }
        .navigationTitle("Spatial Impact")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Decode off the main actor so the view never blocks waiting on
            // a multi-thousand-record JSON file.
            let loaded = await Task.detached(priority: .userInitiated) {
                GNNImpactLoader.load(forCity: cityName)
            }.value

            guard let loaded, !loaded.sites.isEmpty else {
                impact = loaded
                return
            }

            impact = loaded
            if let first = loaded.sites.first {
                position = .region(MKCoordinateRegion(
                    center: first.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)))
            }
            await rebuildGrid()
        }
        .onChange(of: selectedMetric) { _, _ in
            Task { await rebuildGrid() }
        }
        .onChange(of: showAfter) { _, _ in
            Task { await rebuildGrid() }
        }
    }

    // MARK: - Grid rebuilding (cached per metric + before/after)

    private func cacheKey(_ metric: ScoreMetric, _ after: Bool) -> String {
        "\(metric.rawValue)_\(after)"
    }

    private func rebuildGrid() async {
        guard let sites = impact?.sites, !sites.isEmpty else {
            currentCells = []
            return
        }

        let key = cacheKey(selectedMetric, showAfter)
        if let cached = gridCache[key] {
            currentCells = cached
            return
        }

        isBuildingGrid = true
        let metric = selectedMetric
        let after = showAfter
        let built = await Task.detached(priority: .userInitiated) {
            Self.buildGrid(sites: sites, metric: metric, useAfter: after)
        }.value

        gridCache[key] = built
        // Guard against a stale result landing after the user already
        // flipped to a different tab while this was building.
        if metric == selectedMetric && after == showAfter {
            currentCells = built
        }
        isBuildingGrid = false
    }

    // Buckets sites into a fixed-size lat/lon grid (independent of how many
    // sites there are -- 200 or 5,000 both resolve to at most gridSize^2
    // cells) and averages the selected metric's score per cell.
    private static func buildGrid(sites: [GNNImpactSite], metric: ScoreMetric, useAfter: Bool, gridSize: Int = 40) -> [ScoreGridCell] {
        guard !sites.isEmpty else { return [] }
        let lats = sites.map { $0.lat }
        let lons = sites.map { $0.lon }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let latSpan = max(maxLat - minLat, 0.0005)
        let lonSpan = max(maxLon - minLon, 0.0005)
        let latStep = latSpan / Double(gridSize)
        let lonStep = lonSpan / Double(gridSize)

        struct Bucket { var sum = 0.0; var count = 0; var latSum = 0.0; var lonSum = 0.0 }
        var buckets: [Int: Bucket] = [:]

        for site in sites {
            let row = min(gridSize - 1, max(0, Int((site.lat - minLat) / latStep)))
            let col = min(gridSize - 1, max(0, Int((site.lon - minLon) / lonStep)))
            let key = row * gridSize + col
            let score = site.score(for: metric, after: useAfter)
            var b = buckets[key] ?? Bucket()
            b.sum += score
            b.count += 1
            b.latSum += site.lat
            b.lonSum += site.lon
            buckets[key] = b
        }

        let avgLat = (minLat + maxLat) / 2
        let metersPerDegLat = 111_320.0
        let metersPerDegLon = 111_320.0 * cos(avgLat * .pi / 180)
        // Slightly oversized so neighbouring cells overlap and blend
        // together into a continuous gradient rather than a checkerboard.
        let cellRadius = max(latStep * metersPerDegLat, lonStep * metersPerDegLon) * 0.85

        return buckets.values.map { b in
            ScoreGridCell(
                coordinate: CLLocationCoordinate2D(latitude: b.latSum / Double(b.count), longitude: b.lonSum / Double(b.count)),
                avgScore: b.sum / Double(b.count),
                radiusMeters: cellRadius
            )
        }
    }

    // Red (low score) -> yellow -> green (high score), 0-100.
    private func colorForScore(_ score: Double) -> Color {
        let t = max(0.0, min(1.0, score / 100.0))
        let hue = 0.0 + t * 0.33 // 0 = red, 0.33 = green
        return Color(hue: hue, saturation: 0.85, brightness: 0.9)
    }

    // Only shows the metric currently selected in the tab bar (plus the two
    // fields that aren't part of the switcher: canopy coverage and the
    // practical planting grade).
    @ViewBuilder
    private func statsCard(for summary: GNNImpactSummary, metric: ScoreMetric) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("City-Wide Uplift")
                .font(.headline)
                .foregroundColor(.green)

            statRow("Canopy Coverage", summary.canopyCoveragePctBefore, summary.canopyCoveragePctAfter, suffix: "%")
            statRow("\(metric.label) Score", summary.score(for: metric, after: false), summary.score(for: metric, after: true))
            statRow("Practical Grade", summary.practicalGradeBefore, summary.practicalGradeAfter)

            Text("\(summary.siteCount) of \(summary.totalSitesInModel) sites shown")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func statRow(_ label: String, _ before: Double, _ after: Double, suffix: String = "") -> some View {
        let delta = after - before
        HStack {
            Text(label).foregroundColor(.gray)
            Spacer()
            Text("\(String(format: "%.1f", before))\(suffix) → \(String(format: "%.1f", after))\(suffix)")
                .foregroundColor(.white)
                .font(.subheadline)
            Text(delta >= 0 ? "+\(String(format: "%.1f", delta))" : String(format: "%.1f", delta))
                .foregroundColor(delta >= 0 ? .green : .red)
                .font(.caption.bold())
        }
    }
}

// MARK: - Per-metric accessors
//
// NOTE: these assume GNNImpactSite / GNNImpactSummary expose Before/After
// pairs for each metric, following the same naming pattern the original
// file already used for `overallBefore` / `overallAfter`
// (i.e. `shadeBefore/shadeAfter`, `diversityBefore/diversityAfter`,
// `resilienceBefore/resilienceAfter` on the site, and the matching
// `...ScoreBefore/...ScoreAfter` names on the summary). If your model types
// use different property names, or don't have a resilience pair yet
// (the original statsCard didn't show one), add them there first --
// these two extensions are the only place that needs to change.

extension GNNImpactSite {
    func score(for metric: ScoreMetric, after: Bool) -> Double {
        switch (metric, after) {
        case (.overall, false):    return overallBefore
        case (.overall, true):     return overallAfter
        case (.shade, false):      return shadeBefore
        case (.shade, true):       return shadeAfter
        case (.diversity, false):  return diversityBefore
        case (.diversity, true):   return diversityAfter
        }
    }
}

extension GNNImpactSummary {
    func score(for metric: ScoreMetric, after: Bool) -> Double {
        switch (metric, after) {
        case (.overall, false):    return overallScoreBefore
        case (.overall, true):     return overallScoreAfter
        case (.shade, false):      return shadeScoreBefore
        case (.shade, true):       return shadeScoreAfter
        case (.diversity, false):  return diversityScoreBefore
        case (.diversity, true):   return diversityScoreAfter
        }
    }
}

// MARK: - Clean branded loading screen

struct GNNLoadingView: View {
    let cityName: String
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 46))
                .foregroundColor(.green)
                .scaleEffect(pulse ? 1.15 : 0.9)
                .opacity(pulse ? 1.0 : 0.55)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: 4) {
                Text("Mapping \(cityName)'s Impact")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Building the before/after canopy view…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView()
                .tint(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.001)) // keeps hit-testing/layout stable without a hard color block
        .onAppear { pulse = true }
    }
}
