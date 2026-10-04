import Foundation

// Matches {CITY}_rl_game_config.json (schema v2.0 — "GNN Urban Forest
// Analyzer — RL Swap Scheduler"). The game is now framed around curated
// "swap batches" (at-risk species the model already flagged), a full
// scoreTable covering every candidate species, and a single population-
// weighted STARS score as the head-to-head metric against the AI.

struct RLClimateConfig: Codable {
    let currentTempF: Double
    let temp2050F: Double
    let currentRainfallIn: Double
    let rainfall2050In: Double
}

struct RLCityConfig: Codable {
    let cityName: String
    let annualBudget: Double
    let simYears: Int
    let replacementRate: Double
    let costRemoval: Double
    let costPlant: Double
    let costLarge: Double
    let costWater3yr: Double
    let costMaintenance: Double
    let overheadPct: Double
    let climate: RLClimateConfig
    let scoringFormula: String
    let swapCostFormula: String
}

struct SwapBatch: Codable, Identifiable {
    let id: String // matches the uppercase key used in startingInventory/scoreTable
    let speciesName: String
    let priorityLevel: String
    let totalToReplace: Double
    let currentScore: Double
    let urgency: Double
    let scoreGainPerTree: Double
}

struct RLBenchmarkYear: Codable {
    let year: Int
    let action: String
    let actionIndex: Int
    let starsScore: Double
    let pctDone: Double
    let budgetLeft: Double
    let reward: Double
}

struct WinConditions: Codable {
    let description: String
    let aiScore: Double
    let metric: String
}

struct RLGameConfig: Codable {
    let version: String
    let generatedBy: String
    let cityConfig: RLCityConfig
    let swapBatches: [SwapBatch]
    let startingInventory: [String: Double]
    let scoreTable: [String: Double]
    let rlBenchmark: [RLBenchmarkYear]
    let rlPreferences: [String: Double]
    let winConditions: WinConditions
    let instructions: [String]
    let tips: [String]
}

enum RLGameLoader {
    static func load(forCity cityName: String) -> RLGameConfig? {
        let prefix = CityAssets.filePrefix(for: cityName)
        guard let path = Bundle.main.path(forResource: "\(prefix)_rl_game_config", ofType: "json") else {
            print("⚠️ RL game config not found in bundle for \(cityName)")
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONDecoder().decode(RLGameConfig.self, from: data)
        } catch {
            print("⚠️ Failed to decode RL game config for \(cityName): \(error)")
            return nil
        }
    }
}
