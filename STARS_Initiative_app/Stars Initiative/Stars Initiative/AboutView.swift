//
//  AboutView.swift
//  Tree App
//
//  Created by Kovid Kaushik on 7/26/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        Text("About STARS:")
            .font(.largeTitle)
            .bold(true)
        Text("  By 2050, the South Bay’s climate will mirror the high-heat environment of present-day Sacramento, yet cities continue to plant based on historical conditions, risking urban forest failure exactly when cooling, CO₂ sequestration, and ecological services are needed most. This project introduces STARS, a Multi-Criteria-Decision-Analysis framework designed to transition urban forestry from reactive replacement to proactive climate defense. STARS scores species across five dimensions: climate resilience, environmental services, biodiversity, ecological value, and practical considerations, using sigmoid curves for resilience, an exponential drought-decay function, and trajectory-weighted survival scoring for 2050 projections. A Random Forest Classifier model was trained on multiple tree characteristics to identify objective scoring patterns free from human bias.  The framework executed a forest simulation for Cupertino and Mountain View, performing strategic species swaps based on plot size and STARS’ recommendations while enforcing the Santamour 10% genus diversity rule. Validation confirmed the engine's efficacy across four dimensions: the model successfully reconstructed scoring logic from tree characteristics; Climate Analog analysis identified five STARS-recommended species already thriving in Sacramento’s climate; Shannon Diversity Index analysis showed increased biodiversity; and iTree tools validated a sequestration boost. Results were transformative: STARS-optimized planting increased scores by 40.5%, boosted CO2 sequestration by over 2,000 tons, and eliminated $21.5M in municipal liability. STARS proves that the primary lever for urban resilience is not the volume of trees planted, but the intelligence of the selection. STARS provides a scalable, data-driven blueprint to move beyond reactive maintenance and secure a thriving, high-impact canopy for the next generation.")
            .padding(20)
            .font(.system(size: 14))
        
    }
}

#Preview {
    AboutView()
}
