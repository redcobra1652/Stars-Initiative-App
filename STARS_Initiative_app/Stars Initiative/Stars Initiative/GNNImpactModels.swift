import Foundation
import CoreLocation

// Matches {CITY}_ios_impact_export.json produced by export_ios_impact_json()
// in the notebook.

struct GNNImpactSummary: Codable {
    let city: String
    let siteCount: Int
    let totalSitesInModel: Int
    let canopyCoveragePctBefore: Double
    let canopyCoveragePctAfter: Double
    let canopyCoverageUpliftPct: Double
    let diversityScoreBefore: Double
    let diversityScoreAfter: Double
    let shadeScoreBefore: Double
    let shadeScoreAfter: Double
    let overallScoreBefore: Double
    let overallScoreAfter: Double
    let practicalGradeBefore: Double
    let practicalGradeAfter: Double
}

struct GNNImpactSite: Codable, Identifiable {
    let id: Int
    let lat: Double
    let lon: Double
    let speciesBefore: String
    let speciesAfter: String
    let diversityBefore: Double
    let diversityAfter: Double
    let shadeBefore: Double
    let shadeAfter: Double
    let overallBefore: Double
    let overallAfter: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

struct GNNImpactExport: Codable {
    let summary: GNNImpactSummary
    let sites: [GNNImpactSite]
}

enum GNNImpactLoader {
    // Base-path bundle resource, not a subfolder/Assets catalog entry --
    // matches the pattern already used for the Smart Zones CSVs.
    static func load(forCity cityName: String) -> GNNImpactExport? {
        let prefix = CityAssets.filePrefix(for: cityName)
        guard let path = Bundle.main.path(forResource: "\(prefix)_ios_impact_export", ofType: "json") else {
            print("⚠️ GNN impact export not found in bundle for \(cityName)")
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONDecoder().decode(GNNImpactExport.self, from: data)
        } catch {
            print("⚠️ Failed to decode GNN impact export for \(cityName): \(error)")
            return nil
        }
    }
}
