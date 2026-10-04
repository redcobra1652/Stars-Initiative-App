
//
//  PlantingScheduleView.swift
//  Tree App
//
//  Created by Antigravity AI.
//
//  Displays the RL-optimised 25-year urban forestry planting schedule for a city.
//  Data is sourced from the Action Plan xlsx files exported by the STARS pipeline.
//

import SwiftUI

// MARK: - Data models

struct ScheduleYear: Identifiable {
    let id = UUID()
    let year: Int
    let starsScore: Double
    let starsDelta: Double
    let pctSwapsComplete: Double   // 0-100
    let treesReplaced: Int
}

struct SpeciesSwap: Identifiable {
    let id = UUID()
    let removeSpecies: String
    let plantSpecies: String
    let treeCount: Int
    let yrStart: Int
    let yrEnd: Int
    let priority: String
    let starsGainPerTree: Double
    let totalCost: Int
}

// MARK: - Per-city data

struct PlantingScheduleData {

    static func yearData(for city: String) -> [ScheduleYear] {
        switch city {
        case "Cupertino":  return cupertino
        case "Milpitas":   return milpitas
        case "Mountain View": return mtview
        case "Sunnyvale":  return sunnyvale
        default:           return []
        }
    }

    static func swapData(for city: String) -> [SpeciesSwap] {
        switch city {
        case "Cupertino":  return cupertinoSwaps
        case "Milpitas":   return milpitasSwaps
        case "Mountain View": return mtviewSwaps
        case "Sunnyvale":  return sunnyvaleSwaps
        default:           return []
        }
    }

    // MARK: Cupertino year-by-year
    static let cupertino: [ScheduleYear] = [
        .init(year:1,  starsScore:45.16, starsDelta:1.08, pctSwapsComplete:8.0,  treesReplaced:107),
        .init(year:2,  starsScore:46.03, starsDelta:0.86, pctSwapsComplete:13.3, treesReplaced:344),
        .init(year:3,  starsScore:47.84, starsDelta:1.81, pctSwapsComplete:17.6, treesReplaced:431),
        .init(year:4,  starsScore:49.89, starsDelta:2.05, pctSwapsComplete:21.0, treesReplaced:303),
        .init(year:5,  starsScore:51.32, starsDelta:1.43, pctSwapsComplete:25.3, treesReplaced:715),
        .init(year:6,  starsScore:52.60, starsDelta:1.28, pctSwapsComplete:32.0, treesReplaced:362),
        .init(year:7,  starsScore:53.93, starsDelta:1.34, pctSwapsComplete:37.8, treesReplaced:663),
        .init(year:8,  starsScore:55.19, starsDelta:1.26, pctSwapsComplete:42.5, treesReplaced:494),
        .init(year:9,  starsScore:55.38, starsDelta:0.19, pctSwapsComplete:46.7, treesReplaced:247),
        .init(year:10, starsScore:56.77, starsDelta:1.39, pctSwapsComplete:51.8, treesReplaced:652),
        .init(year:11, starsScore:57.32, starsDelta:0.56, pctSwapsComplete:56.0, treesReplaced:65),
        .init(year:12, starsScore:57.81, starsDelta:0.48, pctSwapsComplete:61.3, treesReplaced:318),
        .init(year:13, starsScore:59.01, starsDelta:1.20, pctSwapsComplete:66.7, treesReplaced:405),
        .init(year:14, starsScore:60.28, starsDelta:1.27, pctSwapsComplete:72.0, treesReplaced:266),
        .init(year:15, starsScore:60.34, starsDelta:0.06, pctSwapsComplete:76.0, treesReplaced:256),
        .init(year:16, starsScore:61.81, starsDelta:1.48, pctSwapsComplete:82.7, treesReplaced:398),
        .init(year:17, starsScore:62.78, starsDelta:0.97, pctSwapsComplete:86.5, treesReplaced:281),
        .init(year:18, starsScore:63.37, starsDelta:0.59, pctSwapsComplete:89.4, treesReplaced:334),
        .init(year:19, starsScore:63.83, starsDelta:0.46, pctSwapsComplete:92.2, treesReplaced:16),
        .init(year:20, starsScore:64.76, starsDelta:0.94, pctSwapsComplete:97.3, treesReplaced:232),
        .init(year:21, starsScore:65.18, starsDelta:0.41, pctSwapsComplete:100.0,treesReplaced:2759),
    ]

    // MARK: Milpitas year-by-year
    static let milpitas: [ScheduleYear] = [
        .init(year:1,  starsScore:43.36, starsDelta:0.65, pctSwapsComplete:8.4,  treesReplaced:153),
        .init(year:2,  starsScore:44.27, starsDelta:0.91, pctSwapsComplete:16.9, treesReplaced:229),
        .init(year:3,  starsScore:44.62, starsDelta:0.35, pctSwapsComplete:24.9, treesReplaced:85),
        .init(year:4,  starsScore:46.26, starsDelta:1.64, pctSwapsComplete:29.1, treesReplaced:89),
        .init(year:5,  starsScore:47.67, starsDelta:1.41, pctSwapsComplete:33.5, treesReplaced:375),
        .init(year:6,  starsScore:48.82, starsDelta:1.16, pctSwapsComplete:40.0, treesReplaced:538),
        .init(year:7,  starsScore:49.99, starsDelta:1.17, pctSwapsComplete:46.7, treesReplaced:312),
        .init(year:8,  starsScore:52.03, starsDelta:2.04, pctSwapsComplete:49.6, treesReplaced:66),
        .init(year:9,  starsScore:52.39, starsDelta:0.36, pctSwapsComplete:54.9, treesReplaced:10),
        .init(year:10, starsScore:53.83, starsDelta:1.44, pctSwapsComplete:59.9, treesReplaced:521),
        .init(year:11, starsScore:55.49, starsDelta:1.66, pctSwapsComplete:65.0, treesReplaced:272),
        .init(year:12, starsScore:56.76, starsDelta:1.27, pctSwapsComplete:70.0, treesReplaced:186),
        .init(year:13, starsScore:58.61, starsDelta:1.85, pctSwapsComplete:72.2, treesReplaced:159),
        .init(year:14, starsScore:60.48, starsDelta:1.87, pctSwapsComplete:74.4, treesReplaced:143),
        .init(year:15, starsScore:61.19, starsDelta:0.71, pctSwapsComplete:79.9, treesReplaced:269),
        .init(year:16, starsScore:63.03, starsDelta:1.84, pctSwapsComplete:87.8, treesReplaced:292),
        .init(year:17, starsScore:64.61, starsDelta:1.58, pctSwapsComplete:91.7, treesReplaced:542),
        .init(year:18, starsScore:65.97, starsDelta:1.37, pctSwapsComplete:95.0, treesReplaced:585),
        .init(year:25, starsScore:65.97, starsDelta:0.00, pctSwapsComplete:95.0, treesReplaced:1168),
    ]

    // MARK: Mountain View year-by-year
    static let mtview: [ScheduleYear] = [
        .init(year:1,  starsScore:42.40, starsDelta:1.73, pctSwapsComplete:1.8,  treesReplaced:0),
        .init(year:2,  starsScore:43.94, starsDelta:1.53, pctSwapsComplete:3.6,  treesReplaced:0),
        .init(year:3,  starsScore:45.40, starsDelta:1.47, pctSwapsComplete:5.4,  treesReplaced:0),
        .init(year:4,  starsScore:46.88, starsDelta:1.48, pctSwapsComplete:7.3,  treesReplaced:0),
        .init(year:5,  starsScore:48.28, starsDelta:1.40, pctSwapsComplete:9.6,  treesReplaced:710),
        .init(year:6,  starsScore:49.29, starsDelta:1.00, pctSwapsComplete:11.9, treesReplaced:0),
        .init(year:7,  starsScore:50.30, starsDelta:1.01, pctSwapsComplete:14.1, treesReplaced:0),
        .init(year:8,  starsScore:51.32, starsDelta:1.03, pctSwapsComplete:16.3, treesReplaced:0),
        .init(year:9,  starsScore:52.44, starsDelta:1.11, pctSwapsComplete:18.8, treesReplaced:355),
        .init(year:10, starsScore:53.77, starsDelta:1.33, pctSwapsComplete:22.0, treesReplaced:564),
        .init(year:11, starsScore:55.09, starsDelta:1.32, pctSwapsComplete:25.8, treesReplaced:501),
        .init(year:12, starsScore:55.31, starsDelta:0.22, pctSwapsComplete:37.0, treesReplaced:1065),
        .init(year:13, starsScore:55.63, starsDelta:0.32, pctSwapsComplete:48.1, treesReplaced:666),
        .init(year:14, starsScore:56.96, starsDelta:1.34, pctSwapsComplete:53.2, treesReplaced:44),
        .init(year:15, starsScore:58.32, starsDelta:1.36, pctSwapsComplete:56.5, treesReplaced:6),
        .init(year:16, starsScore:59.64, starsDelta:1.32, pctSwapsComplete:64.0, treesReplaced:10),
        .init(year:17, starsScore:60.88, starsDelta:1.24, pctSwapsComplete:74.0, treesReplaced:175),
        .init(year:18, starsScore:62.14, starsDelta:1.26, pctSwapsComplete:79.8, treesReplaced:8),
        .init(year:19, starsScore:63.52, starsDelta:1.39, pctSwapsComplete:87.4, treesReplaced:316),
        .init(year:20, starsScore:64.95, starsDelta:1.43, pctSwapsComplete:94.4, treesReplaced:401),
        .init(year:21, starsScore:65.83, starsDelta:0.88, pctSwapsComplete:100.0,treesReplaced:2015),
    ]

    // MARK: Sunnyvale year-by-year
    static let sunnyvale: [ScheduleYear] = [
        .init(year:1,  starsScore:46.05, starsDelta:0.72, pctSwapsComplete:13.0, treesReplaced:237),
        .init(year:2,  starsScore:46.56, starsDelta:0.51, pctSwapsComplete:25.7, treesReplaced:174),
        .init(year:3,  starsScore:48.43, starsDelta:1.88, pctSwapsComplete:38.4, treesReplaced:189),
        .init(year:4,  starsScore:49.47, starsDelta:1.04, pctSwapsComplete:46.2, treesReplaced:102),
        .init(year:5,  starsScore:50.84, starsDelta:1.37, pctSwapsComplete:56.5, treesReplaced:95),
        .init(year:6,  starsScore:52.72, starsDelta:1.88, pctSwapsComplete:66.7, treesReplaced:107),
        .init(year:7,  starsScore:55.29, starsDelta:2.56, pctSwapsComplete:76.9, treesReplaced:85),
        .init(year:8,  starsScore:58.32, starsDelta:3.03, pctSwapsComplete:84.9, treesReplaced:167),
        .init(year:9,  starsScore:62.36, starsDelta:4.04, pctSwapsComplete:88.7, treesReplaced:51),
        .init(year:10, starsScore:66.07, starsDelta:3.70, pctSwapsComplete:94.8, treesReplaced:101),
        .init(year:11, starsScore:66.59, starsDelta:0.52, pctSwapsComplete:100.0,treesReplaced:1119),
    ]

    // MARK: Cupertino swaps
    static let cupertinoSwaps: [SpeciesSwap] = [
        .init(removeSpecies:"American Sweet Gum",        plantSpecies:"Catalina Ironwood",   treeCount:618, yrStart:7,  yrEnd:7,  priority:"Priority 4", starsGainPerTree:23.5, totalCost:868290),
        .init(removeSpecies:"Aristocrat Flowering Pear", plantSpecies:"California Buckeye",  treeCount:227, yrStart:21, yrEnd:21, priority:"Priority 4", starsGainPerTree:22.6, totalCost:318935),
        .init(removeSpecies:"Autumn Purple Ash",         plantSpecies:"Desert Willow",       treeCount:216, yrStart:9,  yrEnd:9,  priority:"Priority 4", starsGainPerTree:21.4, totalCost:303480),
        .init(removeSpecies:"Brisbane Box",              plantSpecies:"Holly Oak",            treeCount:76,  yrStart:11, yrEnd:12, priority:"Priority 4", starsGainPerTree:11.4, totalCost:106780),
        .init(removeSpecies:"California Sycamore",       plantSpecies:"Texas Ebony",         treeCount:3,   yrStart:1,  yrEnd:1,  priority:"Priority 4", starsGainPerTree:18.1, totalCost:4215),
        .init(removeSpecies:"Camphor Tree",              plantSpecies:"Interior Live Oak",    treeCount:430, yrStart:3,  yrEnd:4,  priority:"Priority 4", starsGainPerTree:17.1, totalCost:605555),
        .init(removeSpecies:"London Plane 'Bloodgood'",  plantSpecies:"Netleaf Hackberry",   treeCount:291, yrStart:9,  yrEnd:11, priority:"Priority 4", starsGainPerTree:16.9, totalCost:408855),
        .init(removeSpecies:"Maidenhair Tree",           plantSpecies:"Interior Live Oak",   treeCount:373, yrStart:21, yrEnd:21, priority:"Priority 4", starsGainPerTree:21.2, totalCost:524065),
        .init(removeSpecies:"Marina Strawberry Tree",    plantSpecies:"Holly Oak",           treeCount:134, yrStart:7,  yrEnd:8,  priority:"Priority 4", starsGainPerTree:12.2, totalCost:188270),
        .init(removeSpecies:"Modesto Ash",               plantSpecies:"Desert Willow",       treeCount:387, yrStart:15, yrEnd:16, priority:"Priority 4", starsGainPerTree:14.5, totalCost:543735),
        .init(removeSpecies:"Muskogee Crape Myrtle",     plantSpecies:"Holly Oak",           treeCount:476, yrStart:5,  yrEnd:6,  priority:"Priority 4", starsGainPerTree:21.0, totalCost:668780),
        .init(removeSpecies:"Ornamental Pear",           plantSpecies:"Netleaf Hackberry",   treeCount:154, yrStart:1,  yrEnd:2,  priority:"Priority 4", starsGainPerTree:15.4, totalCost:216370),
        .init(removeSpecies:"Purple-leafed Plum",        plantSpecies:"Netleaf Hackberry",   treeCount:223, yrStart:21, yrEnd:21, priority:"Priority 4", starsGainPerTree:19.0, totalCost:313315),
        .init(removeSpecies:"Raywood Ash",               plantSpecies:"Desert Willow",       treeCount:294, yrStart:12, yrEnd:13, priority:"Priority 4", starsGainPerTree:18.6, totalCost:414475),
        .init(removeSpecies:"Red Maple 'October Glory'", plantSpecies:"Netleaf Hackberry",   treeCount:334, yrStart:18, yrEnd:18, priority:"Priority 5", starsGainPerTree:24.6, totalCost:469270),
        .init(removeSpecies:"Shamel Ash",                plantSpecies:"Catalina Ironwood",   treeCount:294, yrStart:2,  yrEnd:3,  priority:"Priority 4", starsGainPerTree:15.1, totalCost:414475),
        .init(removeSpecies:"Southern Magnolia",         plantSpecies:"Coast Live Oak",      treeCount:421, yrStart:16, yrEnd:17, priority:"Priority 4", starsGainPerTree:17.4, totalCost:592910),
        .init(removeSpecies:"Stone Fruit Species",       plantSpecies:"Coast Live Oak",      treeCount:202, yrStart:14, yrEnd:14, priority:"Priority 4", starsGainPerTree:21.3, totalCost:283810),
        .init(removeSpecies:"Tuscarora Crape Myrtle",    plantSpecies:"Western Redbud",      treeCount:831, yrStart:21, yrEnd:21, priority:"Priority 4", starsGainPerTree:14.6, totalCost:1168960),
        .init(removeSpecies:"Water Gum Tree",            plantSpecies:"Western Redbud",      treeCount:190, yrStart:14, yrEnd:15, priority:"Priority 4", starsGainPerTree:12.6, totalCost:266950),
    ]

    // MARK: Milpitas swaps
    static let milpitasSwaps: [SpeciesSwap] = [
        .init(removeSpecies:"American Sweet Gum",    plantSpecies:"California Buckeye",  treeCount:537, yrStart:25, yrEnd:25, priority:"Priority 4", starsGainPerTree:23.5, totalCost:754485),
        .init(removeSpecies:"Autumn Purple Ash",     plantSpecies:"Desert Willow",       treeCount:9,   yrStart:25, yrEnd:25, priority:"Priority 4", starsGainPerTree:20.7, totalCost:14050),
        .init(removeSpecies:"Brisbane Box",          plantSpecies:"Holly Oak",           treeCount:60,  yrStart:25, yrEnd:25, priority:"Priority 4", starsGainPerTree:11.2, totalCost:84300),
        .init(removeSpecies:"California Sycamore",   plantSpecies:"Desert Willow",       treeCount:10,  yrStart:25, yrEnd:25, priority:"Priority 4", starsGainPerTree:17.9, totalCost:15455),
        .init(removeSpecies:"Camphor Tree",          plantSpecies:"Desert Willow",       treeCount:90,  yrStart:4,  yrEnd:5,  priority:"Priority 4", starsGainPerTree:15.7, totalCost:126450),
        .init(removeSpecies:"Chinese Pistache",      plantSpecies:"Interior Live Oak",   treeCount:528, yrStart:6,  yrEnd:7,  priority:"Priority 4", starsGainPerTree:10.9, totalCost:741840),
        .init(removeSpecies:"Coast Redwood",         plantSpecies:"Holly Oak",           treeCount:246, yrStart:16, yrEnd:17, priority:"Priority 5", starsGainPerTree:29.4, totalCost:345630),
        .init(removeSpecies:"London Plane 'Bloodgood'", plantSpecies:"Desert Willow",   treeCount:1048,yrStart:17, yrEnd:18, priority:"Priority 4", starsGainPerTree:18.0, totalCost:1471035),
        .init(removeSpecies:"Maidenhair Tree",       plantSpecies:"Holly Oak",           treeCount:189, yrStart:2,  yrEnd:3,  priority:"Priority 4", starsGainPerTree:20.6, totalCost:265545),
        .init(removeSpecies:"Marina Strawberry Tree",plantSpecies:"Valley Oak",          treeCount:42,  yrStart:11, yrEnd:12, priority:"Priority 4", starsGainPerTree:11.5, totalCost:59010),
        .init(removeSpecies:"Modesto Ash",           plantSpecies:"Catalina Ironwood",   treeCount:475, yrStart:12, yrEnd:15, priority:"Priority 4", starsGainPerTree:15.1, totalCost:668780),
        .init(removeSpecies:"Muskogee Crape Myrtle", plantSpecies:"Texas Ebony",         treeCount:777, yrStart:10, yrEnd:11, priority:"Priority 4", starsGainPerTree:21.7, totalCost:1091685),
        .init(removeSpecies:"Ornamental Pear",       plantSpecies:"Coast Live Oak",      treeCount:548, yrStart:25, yrEnd:25, priority:"Priority 4", starsGainPerTree:16.8, totalCost:771345),
        .init(removeSpecies:"Purple-leafed Plum",    plantSpecies:"Valley Oak",          treeCount:153, yrStart:1,  yrEnd:2,  priority:"Priority 4", starsGainPerTree:18.8, totalCost:214965),
        .init(removeSpecies:"Raywood Ash",           plantSpecies:"Valley Oak",          treeCount:204, yrStart:7,  yrEnd:9,  priority:"Priority 4", starsGainPerTree:18.3, totalCost:288025),
        .init(removeSpecies:"Red Maple 'October Glory'", plantSpecies:"Netleaf Hackberry",treeCount:379,yrStart:15, yrEnd:16, priority:"Priority 5", starsGainPerTree:25.1, totalCost:533900),
        .init(removeSpecies:"Shamel Ash",            plantSpecies:"Valley Oak",          treeCount:101, yrStart:1,  yrEnd:1,  priority:"Priority 4", starsGainPerTree:13.9, totalCost:141905),
        .init(removeSpecies:"Southern Magnolia",     plantSpecies:"Interior Live Oak",   treeCount:558, yrStart:5,  yrEnd:6,  priority:"Priority 4", starsGainPerTree:18.1, totalCost:783990),
        .init(removeSpecies:"Stone Fruit Species",   plantSpecies:"Valley Oak",          treeCount:9,   yrStart:9,  yrEnd:10, priority:"Priority 4", starsGainPerTree:19.9, totalCost:14050),
        .init(removeSpecies:"White Alder",           plantSpecies:"Valley Oak",          treeCount:24,  yrStart:3,  yrEnd:3,  priority:"Priority 4", starsGainPerTree:21.3, totalCost:33720),
    ]

    // MARK: Mountain View swaps
    static let mtviewSwaps: [SpeciesSwap] = [
        .init(removeSpecies:"American Sweet Gum",        plantSpecies:"Interior Live Oak",   treeCount:930,  yrStart:11, yrEnd:14, priority:"Priority 4", starsGainPerTree:25.9, totalCost:1308055),
        .init(removeSpecies:"Brisbane Box",              plantSpecies:"Catalina Ironwood",   treeCount:195,  yrStart:14, yrEnd:18, priority:"Priority 4", starsGainPerTree:14.0, totalCost:273975),
        .init(removeSpecies:"Chinese Pistache",          plantSpecies:"California Buckeye",  treeCount:1324, yrStart:11, yrEnd:12, priority:"Priority 4", starsGainPerTree:13.4, totalCost:1860220),
        .init(removeSpecies:"Coast Redwood",             plantSpecies:"Desert Willow",       treeCount:1629, yrStart:5,  yrEnd:11, priority:"Priority 5", starsGainPerTree:33.4, totalCost:1791375),
        .init(removeSpecies:"Cork Oak",                  plantSpecies:"Netleaf Hackberry",   treeCount:18,   yrStart:18, yrEnd:19, priority:"Priority 4", starsGainPerTree:17.8, totalCost:25290),
        .init(removeSpecies:"Modesto Ash",               plantSpecies:"Holly Oak",           treeCount:194,  yrStart:21, yrEnd:21, priority:"Priority 4", starsGainPerTree:15.3, totalCost:273975),
        .init(removeSpecies:"Muskogee Crape Myrtle",     plantSpecies:"Valley Oak",          treeCount:796,  yrStart:21, yrEnd:21, priority:"Priority 4", starsGainPerTree:23.6, totalCost:1118380),
        .init(removeSpecies:"Raywood Ash",               plantSpecies:"Netleaf Hackberry",   treeCount:360,  yrStart:21, yrEnd:21, priority:"Priority 4", starsGainPerTree:20.8, totalCost:505800),
        .init(removeSpecies:"Red Maple 'October Glory'", plantSpecies:"Netleaf Hackberry",   treeCount:454,  yrStart:21, yrEnd:21, priority:"Priority 5", starsGainPerTree:26.9, totalCost:637870),
        .init(removeSpecies:"Southern Magnolia",         plantSpecies:"Texas Ebony",         treeCount:912,  yrStart:19, yrEnd:21, priority:"Priority 4", starsGainPerTree:20.4, totalCost:1281360),
        .init(removeSpecies:"Stone Fruit Species",       plantSpecies:"Coast Live Oak",      treeCount:4,    yrStart:21, yrEnd:21, priority:"Priority 4", starsGainPerTree:22.2, totalCost:5620),
        .init(removeSpecies:"White Alder",               plantSpecies:"Catalina Ironwood",   treeCount:15,   yrStart:15, yrEnd:16, priority:"Priority 4", starsGainPerTree:23.6, totalCost:22480),
    ]

    // MARK: Sunnyvale swaps
    static let sunnyvaleSwaps: [SpeciesSwap] = [
        .init(removeSpecies:"Aristocrat Flowering Pear", plantSpecies:"Interior Live Oak",   treeCount:94,  yrStart:5,  yrEnd:5,  priority:"Priority 4", starsGainPerTree:15.0, totalCost:133475),
        .init(removeSpecies:"Camphor Tree",              plantSpecies:"California Buckeye",  treeCount:102, yrStart:4,  yrEnd:4,  priority:"Priority 4", starsGainPerTree:8.9,  totalCost:143310),
        .init(removeSpecies:"Chinese Pistache",          plantSpecies:"Desert Willow",       treeCount:331, yrStart:11, yrEnd:11, priority:"Priority 4", starsGainPerTree:3.5,  totalCost:465055),
        .init(removeSpecies:"Coast Redwood",             plantSpecies:"Netleaf Hackberry",   treeCount:152, yrStart:9,  yrEnd:10, priority:"Priority 5", starsGainPerTree:22.1, totalCost:213560),
        .init(removeSpecies:"Holly Oak",                 plantSpecies:"Coast Live Oak",      treeCount:183, yrStart:2,  yrEnd:3,  priority:"Priority 1", starsGainPerTree:0.0,  totalCost:257115),
        .init(removeSpecies:"London Plane 'Bloodgood'",  plantSpecies:"California Buckeye",  treeCount:130, yrStart:3,  yrEnd:3,  priority:"Priority 4", starsGainPerTree:9.4,  totalCost:182650),
        .init(removeSpecies:"Maidenhair Tree",           plantSpecies:"Texas Ebony",         treeCount:167, yrStart:8,  yrEnd:8,  priority:"Priority 4", starsGainPerTree:13.7, totalCost:234635),
        .init(removeSpecies:"Muskogee Crape Myrtle",     plantSpecies:"Holly Oak",           treeCount:85,  yrStart:7,  yrEnd:7,  priority:"Priority 4", starsGainPerTree:12.0, totalCost:119425),
        .init(removeSpecies:"Purple-leafed Plum",        plantSpecies:"Interior Live Oak",   treeCount:106, yrStart:6,  yrEnd:6,  priority:"Priority 4", starsGainPerTree:11.6, totalCost:150335),
        .init(removeSpecies:"Shamel Ash",                plantSpecies:"Holly Oak",           treeCount:82,  yrStart:11, yrEnd:11, priority:"Priority 4", starsGainPerTree:6.9,  totalCost:115210),
        .init(removeSpecies:"Southern Magnolia",         plantSpecies:"Netleaf Hackberry",   treeCount:706, yrStart:11, yrEnd:11, priority:"Priority 4", starsGainPerTree:11.2, totalCost:363895),
        .init(removeSpecies:"Tuscarora Crape Myrtle",    plantSpecies:"Interior Live Oak",   treeCount:76,  yrStart:1,  yrEnd:2,  priority:"Priority 4", starsGainPerTree:5.5,  totalCost:106780),
        .init(removeSpecies:"Water Gum Tree",            plantSpecies:"Holly Oak",           treeCount:211, yrStart:1,  yrEnd:1,  priority:"Priority 4", starsGainPerTree:6.0,  totalCost:296455),
    ]
}

// MARK: - Main view

enum ScheduleTab { case timeline, swaps }

struct PlantingScheduleView: View {
    let cityName: String
    @State private var activeTab: ScheduleTab = .timeline
    @State private var selectedYear: ScheduleYear? = nil

    private var years: [ScheduleYear] { PlantingScheduleData.yearData(for: cityName) }
    private var swaps: [SpeciesSwap] { PlantingScheduleData.swapData(for: cityName) }

    private var finalScore: Double { years.last?.starsScore ?? 0 }
    private var startScore: Double { years.first?.starsScore ?? 0 }
    private var totalTrees: Int { years.reduce(0) { $0 + $1.treesReplaced } }
    private var totalYears: Int { years.last?.year ?? 25 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                summaryHeader
                tabPicker
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                Divider().background(Color(white: 0.2))

                ScrollView {
                    if activeTab == .timeline {
                        timelineContent
                    } else {
                        swapContent
                    }
                }
            }
        }
        .navigationTitle("Planting Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Summary header
    private var summaryHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                summaryKPI("Start", String(format: "%.1f", startScore), "STARS", .gray)
                Divider().frame(height: 44).background(Color(white: 0.2))
                summaryKPI("Final", String(format: "%.1f", finalScore), "STARS", .green)
                Divider().frame(height: 44).background(Color(white: 0.2))
                summaryKPI("Gain", String(format: "+%.1f", finalScore - startScore), "pts", .cyan)
                Divider().frame(height: 44).background(Color(white: 0.2))
                summaryKPI("Swaps", "\(totalTrees)", "trees", Color(white: 0.75))
            }
            .background(Color(white: 0.07))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func summaryKPI(_ label: String, _ value: String, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(Color(white: 0.45))
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(unit)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(Color(white: 0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: Tab picker
    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabButton("Timeline", tab: .timeline, icon: "chart.line.uptrend.xyaxis")
            tabButton("Species Swaps", tab: .swaps, icon: "arrow.triangle.2.circlepath")
        }
        .background(Color(white: 0.1))
        .cornerRadius(10)
        .padding(.top, 8)
    }

    private func tabButton(_ title: String, tab: ScheduleTab, icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(activeTab == tab ? Color.green : Color.clear)
            .foregroundColor(activeTab == tab ? .black : Color(white: 0.55))
            .cornerRadius(10)
        }
    }

    // MARK: Timeline tab
    private var timelineContent: some View {
        VStack(spacing: 0) {
            // Mini STARS chart
            starsProgressChart
                .padding(.horizontal)
                .padding(.top, 16)

            // Year cards
            VStack(spacing: 8) {
                ForEach(years) { yr in
                    YearCard(year: yr, maxStars: finalScore, isSelected: selectedYear?.id == yr.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedYear = selectedYear?.id == yr.id ? nil : yr
                            }
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    // Inline sparkline-style chart
    private var starsProgressChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STARS Score Trajectory")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(white: 0.5))
                .textCase(.uppercase)
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let minS = (years.map(\.starsScore).min() ?? 40) - 2
                let maxS = (years.map(\.starsScore).max() ?? 70) + 2
                let pts = years.enumerated().map { (i, yr) -> CGPoint in
                    let x = years.count > 1 ? CGFloat(i) / CGFloat(years.count - 1) * w : w / 2
                    let y = h - CGFloat((yr.starsScore - minS) / (maxS - minS)) * h
                    return CGPoint(x: x, y: y)
                }
                ZStack {
                    // Area fill
                    if pts.count > 1 {
                        Path { path in
                            path.move(to: CGPoint(x: pts[0].x, y: h))
                            for pt in pts { path.addLine(to: pt) }
                            path.addLine(to: CGPoint(x: pts.last!.x, y: h))
                            path.closeSubpath()
                        }
                        .fill(LinearGradient(
                            colors: [Color.green.opacity(0.25), Color.clear],
                            startPoint: .top, endPoint: .bottom))

                        // Line
                        Path { path in
                            path.move(to: pts[0])
                            for pt in pts.dropFirst() { path.addLine(to: pt) }
                        }
                        .stroke(Color.green, lineWidth: 2)
                    }
                    // Dots
                    ForEach(pts.indices, id: \.self) { i in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                            .position(pts[i])
                    }
                }
            }
            .frame(height: 90)
            .background(Color(white: 0.06))
            .cornerRadius(10)
        }
    }

    // MARK: Swaps tab
    private var swapContent: some View {
        VStack(spacing: 8) {
            Text("Sorted by STARS gain per tree (highest first)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color(white: 0.4))
                .padding(.top, 12)

            ForEach(swaps.sorted { $0.starsGainPerTree > $1.starsGainPerTree }) { swap in
                SwapCard(swap: swap)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}

// MARK: - Year card

struct YearCard: View {
    let year: ScheduleYear
    let maxStars: Double
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(alignment: .center, spacing: 12) {
                // Year bubble
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(isSelected ? 0.25 : 0.12))
                        .frame(width: 42, height: 42)
                    VStack(spacing: 0) {
                        Text("YR")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.green.opacity(0.7))
                        Text("\(year.year)")
                            .font(.system(size: 17, weight: .black, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(String(format: "%.2f", year.starsScore))
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text(year.starsDelta > 0 ? String(format: "+%.2f", year.starsDelta) : String(format: "%.2f", year.starsDelta))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(year.starsDelta > 0 ? .green : .orange)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background((year.starsDelta > 0 ? Color.green : Color.orange).opacity(0.12))
                            .cornerRadius(4)
                    }
                    // Swap progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(white: 0.18))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.green.opacity(0.8))
                                .frame(width: geo.size.width * CGFloat(year.pctSwapsComplete / 100), height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", year.pctSwapsComplete))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Text("swaps")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(Color(white: 0.4))
                }
            }
            .padding(12)

            // Expanded detail
            if isSelected {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().background(Color(white: 0.2))
                    HStack(spacing: 0) {
                        expandedStat("STARS", String(format: "%.2f", year.starsScore), .green)
                        Divider().frame(height: 36).background(Color(white: 0.2))
                        expandedStat("Δ STARS", year.starsDelta > 0 ? String(format: "+%.2f", year.starsDelta) : String(format: "%.2f", year.starsDelta), year.starsDelta > 0 ? .green : .orange)
                        Divider().frame(height: 36).background(Color(white: 0.2))
                        expandedStat("Trees Swapped", "\(year.treesReplaced)", .cyan)
                        Divider().frame(height: 36).background(Color(white: 0.2))
                        expandedStat("% Complete", String(format: "%.1f%%", year.pctSwapsComplete), Color(white: 0.75))
                    }
                    .background(Color(white: 0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color(white: isSelected ? 0.1 : 0.13))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green.opacity(0.5) : Color(white: 0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }

    private func expandedStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(Color(white: 0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Swap card

struct SwapCard: View {
    let swap: SpeciesSwap
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3)) { expanded.toggle() } }) {
                HStack(alignment: .center, spacing: 12) {
                    // Arrow icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        // Remove → Plant
                        Text(swap.removeSpecies)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(white: 0.65))
                            .strikethrough(true, color: Color(white: 0.35))
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                            Text(swap.plantSpecies)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+\(String(format: "%.1f", swap.starsGainPerTree))")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.green)
                        Text("STARS/tree")
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundColor(Color(white: 0.4))
                    }

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.4))
                }
                .padding(12)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().background(Color(white: 0.2))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        swapDetailPill("Trees", "\(swap.treeCount)", .cyan)
                        swapDetailPill("Year", swap.yrStart == swap.yrEnd ? "Yr \(swap.yrStart)" : "Yr \(swap.yrStart)–\(swap.yrEnd)", .white)
                        swapDetailPill("Priority", swap.priority.replacingOccurrences(of: "Priority ", with: "P"), .orange)
                        swapDetailPill("Total Cost", "$\(formatCost(swap.totalCost))", Color(white: 0.7))
                        swapDetailPill("Cost/tree", "$\(swap.treeCount > 0 ? formatCost(swap.totalCost / swap.treeCount) : "—")", Color(white: 0.7))
                        swapDetailPill("STARS Gain", "+\(String(format: "%.1f", swap.starsGainPerTree))/tree", .green)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color(white: expanded ? 0.1 : 0.13))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(expanded ? 0.4 : 0.15), lineWidth: expanded ? 1.5 : 1)
        )
    }

    private func swapDetailPill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(white: 0.14))
        .cornerRadius(7)
    }

    private func formatCost(_ val: Int) -> String {
        let d = Double(val)
        if d >= 1_000_000 { return String(format: "%.1fM", d / 1_000_000) }
        if d >= 1_000 { return String(format: "%.0fK", d / 1_000) }
        return "\(val)"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PlantingScheduleView(cityName: "Cupertino")
    }
}
