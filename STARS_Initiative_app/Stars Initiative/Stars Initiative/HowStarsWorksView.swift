//
//  HowStarsWorksView.swift
//  Tree App
//
//  Created by Kovid Kaushik on 7/6/25.
//

import SwiftUI

// MARK: - Section Model
private struct StarsSection: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let heading: String
    let subsections: [StarsSubsection]
}

private struct StarsSubsection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

// MARK: - Main View
struct HowStarsWorksView: View {

    private let sections: [StarsSection] = [

        StarsSection(
            icon: "star.circle.fill",
            iconColor: .green,
            heading: "What is STARS?",
            subsections: [
                StarsSubsection(
                    title: "Strategic Tree-planting for Accelerated Resilience & Sustainability",
                    body: "By 2050, the South Bay's climate will mirror the high-heat environment of present-day Sacramento. STARS is a data-driven framework that transitions urban forestry from reactive replacement to proactive climate defense — selecting the right species, in the right place, for the right future."
                ),
                StarsSubsection(
                    title: "The Problem with Status Quo Planting",
                    body: "Cities continue to plant trees based on historical climate conditions. Many of today's beloved urban trees — Coast Redwood, Autumn Purple Ash — are projected to face severe hydraulic stress and early mortality by 2050, wasting city investment and erasing critical ecosystem services exactly when they are needed most."
                )
            ]
        ),

        StarsSection(
            icon: "chart.bar.xaxis",
            iconColor: .cyan,
            heading: "MCDA Scoring Engine",
            subsections: [
                StarsSubsection(
                    title: "Five-Pillar Framework",
                    body: "Every candidate species is scored across five evidence-based pillars:\n• Climate Resilience (35%) — sigmoid biological-stress survival curve against 2050 projections\n• Environmental Services (25%) — carbon sequestration scaled by survival probability ('Resilience Discount')\n• Diversity Resilience (15%) — exponential penalty for over-represented genera (Santamour Rule)\n• Practical Considerations (15%) — pruning burden, pavement damage, utility clearance, litter\n• Ecological Value (10%) — native habitat support, rare-native rarity multiplier up to 1.5×"
                ),
                StarsSubsection(
                    title: "Climate Analog Validation",
                    body: "Five STARS-recommended species (Holly Oak, Desert Willow, California Fan Palm, Valley Oak, Texas Ebony) were confirmed to already thrive in Sacramento's present-day climate — the same conditions projected for the South Bay in 2050. This real-world validation proves the model's predictive accuracy."
                ),
                StarsSubsection(
                    title: "Simulation Results",
                    body: "A full forest simulation for Cupertino and Mountain View showed: +40.5% average STARS score improvement, +2,000 tonnes of CO₂ sequestration, and elimination of $21.5 M in projected municipal liability — all through species selection alone."
                )
            ]
        ),

        StarsSection(
            icon: "circle.hexagongrid.fill",
            iconColor: .purple,
            heading: "Graph Neural Network (GNN)",
            subsections: [
                StarsSubsection(
                    title: "Spatial Optimization Pipeline",
                    body: "Built with PyTorch Geometric, the GNN constructs a node-edge graph of every planting zone in a city. Each node encodes a site's attributes (soil type, canopy gap, wire presence, microclimate temperature). Edges connect neighbouring sites within a configurable radius."
                ),
                StarsSubsection(
                    title: "Neighbourhood-Aware Recommendations",
                    body: "By passing messages along edges, the GNN ensures newly planted trees complement the existing canopy. It actively maximises microclimate cooling, genus diversity across adjacent parcels, and biodiversity — preventing localised Santamour bottlenecks that a site-by-site approach would miss."
                ),
                StarsSubsection(
                    title: "SpatialEcoGNN Architecture",
                    body: "The model uses three Graph Convolutional layers (hidden size 128) followed by a fully-connected head that outputs a per-site priority score. It was trained on Cupertino, Mountain View, Milpitas, and Sunnyvale datasets and exports per-site impact predictions — viewable in the Spatial Impact Map."
                )
            ]
        ),

        StarsSection(
            icon: "gamecontroller.fill",
            iconColor: .orange,
            heading: "Reinforcement Learning Agent",
            subsections: [
                StarsSubsection(
                    title: "Urban Forestry as a Decision Game",
                    body: "STARS frames city-scale planting as a sequential decision problem: at each step the agent selects a species for an unplanted site, aiming to maximise the cumulative ecosystem-service reward over the entire urban forest."
                ),
                StarsSubsection(
                    title: "Agent Architecture",
                    body: "The RL agent uses a Proximal Policy Optimisation (PPO) algorithm with a custom reward function that combines STARS score, diversity bonus, and a long-term financial savings term. The state space encodes current genus counts, site attributes, and remaining budget."
                ),
                StarsSubsection(
                    title: "Beat the RL Agent",
                    body: "Inside each city's detail view you can challenge the trained agent directly. You and the agent take turns making planting decisions — try to outscore it on ecosystem value! Scores are tracked in real-time so you can see exactly how STARS reasoning compares to human intuition."
                )
            ]
        ),

        StarsSection(
            icon: "lightbulb.fill",
            iconColor: .yellow,
            heading: "Key Takeaway",
            subsections: [
                StarsSubsection(
                    title: "Intelligence > Volume",
                    body: "The primary lever for urban resilience is not the number of trees planted, but the intelligence of the selection. STARS provides a scalable, peer-validated, data-driven blueprint to secure a thriving, high-impact canopy for the next generation — without planting a single additional tree."
                )
            ]
        )
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Hero header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How STARS Works")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("The science, the models, and the AI behind the initiative.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 4)

                    // Section cards
                    ForEach(sections) { section in
                        SectionCard(section: section)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("How STARS Works")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Section Card
private struct SectionCard: View {
    let section: StarsSection
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: section.icon)
                        .font(.title2)
                        .foregroundColor(section.iconColor)
                        .frame(width: 36)

                    Text(section.heading)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(white: 0.15))
                .cornerRadius(expanded ? 0 : 12)
                .cornerRadius(12, corners: expanded ? [.topLeft, .topRight] : .allCorners)
            }
            .buttonStyle(.plain)

            // Expanded subsections
            if expanded {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(section.subsections) { sub in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(sub.title)
                                .font(.subheadline).bold()
                                .foregroundColor(section.iconColor)
                            Text(sub.body)
                                .font(.callout)
                                .foregroundColor(Color(white: 0.75))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if sub.id != section.subsections.last?.id {
                            Divider().background(Color.white.opacity(0.08))
                        }
                    }
                }
                .padding()
                .background(Color(white: 0.10))
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Rounded corner helper
private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        HowStarsWorksView()
    }
}
