import Foundation

// Shared mapping from the app's display city name to the file prefix used by
// every exported asset (PNGs, Smart Zones CSVs, and now the GNN/RL JSON
// exports). This mirrors the `prefix` switch already used in
// CityDetailView.graphs, factored out so the JSON loaders below stay in sync
// with it. If the notebook's CITY_NAME variable produced filenames that
// don't match these prefixes (e.g. "Mountain View_..." with a space instead
// of "MtView_..."), either rename the exported files to match, or edit this
// switch to match what's actually in the bundle.
enum CityAssets {
    static func filePrefix(for cityName: String) -> String {
        switch cityName {
        case "Mountain View": return "MtView"
        case "Milpitas":      return "Milpitas"
        case "Sunnyvale":     return "Sunnyvale"
        default:              return "Cupertino"
        }
    }
}
