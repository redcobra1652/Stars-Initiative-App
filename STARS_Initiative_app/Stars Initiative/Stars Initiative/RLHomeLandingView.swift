//
//  RLHomeLandingView.swift
//  Tree App
//
//  Created by Antigravity AI.
//
//  Home landing screen for the RL feature.
//  Styled similarly to the STARS Tree Recommendations home screen.
//  Offers two cards:
//    • Beat the RL Agent (existing RLGameView)
//    • View Planting Schedule (new PlantingScheduleView)
//

import SwiftUI

struct RLHomeLandingView: View {
    let cityName: String

    @State private var showTitle  = false
    @State private var showSub    = false
    @State private var showCard1  = false
    @State private var showCard2  = false

    // KPI values per city (final STARS, start STARS, total years)
    private var cityMeta: (start: Double, final: Double, years: Int, trees: Int) {
        switch cityName {
        case "Cupertino":      return (45.1, 65.2, 21, 9648)
        case "Milpitas":       return (42.7, 66.0, 25, 5889)
        case "Mountain View":  return (40.7, 65.8, 21, 6836)
        case "Sunnyvale":      return (45.3, 66.6, 11, 2427)
        default:               return (44.0, 65.0, 25, 5000)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // MARK: Header
                    VStack(spacing: 6) {
                        Text("RL Optimizer")
                            .font(.system(size: 32, weight: .heavy, design: .default))
                            .foregroundColor(.white)
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 18)
                            .animation(.easeOut(duration: 0.7), value: showTitle)

                        Text("\(cityName)  ·  25-Year Urban Forest Strategy")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Color(white: 0.5))
                            .multilineTextAlignment(.center)
                            .opacity(showSub ? 1 : 0)
                            .offset(y: showSub ? 0 : 10)
                            .animation(.easeOut(duration: 0.6).delay(0.15), value: showSub)
                    }
                    .padding(.top, 32)

                    // MARK: KPI strip
                    HStack(spacing: 0) {
                        kpiPill("Baseline", String(format: "%.1f", cityMeta.start), "STARS", .gray)
                        Divider().frame(height: 44).background(Color(white: 0.2))
                        kpiPill("Target",   String(format: "%.1f", cityMeta.final), "STARS", .green)
                        Divider().frame(height: 44).background(Color(white: 0.2))
                        kpiPill("Horizon",  "\(cityMeta.years) yrs", "plan",  Color(white: 0.7))
                        Divider().frame(height: 44).background(Color(white: 0.2))
                        kpiPill("Swaps",    "\(cityMeta.trees)", "trees", .cyan)
                    }
                    .background(Color(white: 0.07))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(white: 0.18), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .opacity(showSub ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.25), value: showSub)

                    // MARK: Card 1 — Beat the RL Agent
                    NavigationLink(destination: RLGameView(cityName: cityName)) {
                        featureCard(
                            icon: "gamecontroller.fill",
                            iconColor: .purple,
                            badge: "INTERACTIVE",
                            title: "Beat the RL Agent",
                            body: "Take control of \(cityName)'s urban forest over 25 years. Make planting & swap decisions each year and see if your strategy can out-score the AI's optimised plan.",
                            cta: "Play Now",
                            accentColor: .purple
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(showCard1 ? 1 : 0)
                    .offset(y: showCard1 ? 0 : 24)
                    .animation(.easeOut(duration: 0.65), value: showCard1)
                    .padding(.horizontal)

                    // MARK: Card 2 — Planting Schedule
                    NavigationLink(destination: PlantingScheduleView(cityName: cityName)) {
                        featureCard(
                            icon: "calendar.badge.clock",
                            iconColor: .green,
                            badge: "DATA",
                            title: "View Planting Schedule",
                            body: "Explore the RL agent's full \(cityMeta.years)-year roadmap — year-by-year STARS score trajectory, species swap batches, costs, and priorities.",
                            cta: "Open Schedule",
                            accentColor: .green
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(showCard2 ? 1 : 0)
                    .offset(y: showCard2 ? 0 : 24)
                    .animation(.easeOut(duration: 0.65), value: showCard2)
                    .padding(.horizontal)

                    // MARK: Footer blurb
                    Text("The RL planner uses a Reinforcement Learning agent trained with GNN-derived STARS scores to sequence species swaps that maximise long-term canopy resilience within the annual budget.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(showCard2 ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.15), value: showCard2)

                    Spacer(minLength: 32)
                }
            }
        }
        .navigationTitle("RL Optimizer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            showTitle = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showSub  = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showCard1 = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { showCard2 = true }
        }
    }

    // MARK: - KPI pill
    private func kpiPill(_ label: String, _ value: String, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 7, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(white: 0.4))
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 17, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(unit)
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(Color(white: 0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Feature card
    private func featureCard(
        icon: String,
        iconColor: Color,
        badge: String,
        title: String,
        body: String,
        cta: String,
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top accent bar
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.8), accentColor.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .cornerRadius(3)

            VStack(alignment: .leading, spacing: 16) {
                // Icon row
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentColor.opacity(0.14))
                            .frame(width: 52, height: 52)
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        // Badge
                        Text(badge)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.12))
                            .cornerRadius(5)

                        Text(title)
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Body
                Text(body)
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.65))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                // CTA button
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Text(cta)
                            .font(.system(size: 14, weight: .semibold, design: .default))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(accentColor)
                    .cornerRadius(10)
                }
            }
            .padding(18)
        }
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        RLHomeLandingView(cityName: "Cupertino")
    }
}
