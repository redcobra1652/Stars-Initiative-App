//
//  ContentView.swift
//  Tree App
//
//  Created by Kovid Kaushik on 7/6/25.
//

import SwiftUI

struct ContentView: View {

    @State private var moveUp = false
    @State private var showImage = false
    @State private var showButton1 = false
    @State private var showButton2 = false
    @State private var showButton3 = false

    var body: some View {

        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 20) {

                    Spacer()

                    // MARK: Header
                    VStack(spacing: 10) {
                        Text("STARS Initiative")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)

                        Text("Strategic Tree-planting for Accelerated Resilience and Sustainability")
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .offset(y: moveUp ? 0 : 200)
                    .animation(.easeInOut(duration: 2.5), value: moveUp)

                    // MARK: Image
                    Image("home_treeimg")
                        .resizable()
                        .scaledToFill()
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(Circle())
                        .opacity(showImage ? 1 : 0)
                        .offset(y: showImage ? 0 : 40)
                        .animation(.easeOut(duration: 1.0), value: showImage)


                    // MARK: Buttons

                    NavigationLink(destination: HowStarsWorksView()) {
                        Text("Learn what Drives STARS")
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .opacity(showButton1 ? 1 : 0)
                    .offset(y: showButton1 ? 0 : 25)
                    .animation(.easeOut(duration: 0.8), value: showButton1)

                    NavigationLink(destination: TreesToPlant()) {
                        Text("Tailored STARS Tree Recommendations")
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .opacity(showButton2 ? 1 : 0)
                    .offset(y: showButton2 ? 0 : 25)
                    .animation(.easeOut(duration: 0.8), value: showButton2)

                    NavigationLink(destination: CityCompare()) {
                        Text("The Impact of STARS Across Cities")
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .opacity(showButton3 ? 1 : 0)
                    .offset(y: showButton3 ? 0 : 25)
                    .animation(.easeOut(duration: 0.8), value: showButton3)

                    Spacer()
                }
                .padding()
            }
            .onAppear {

                // Hold title in the center for a moment.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

                    moveUp = true

                    // Dramatic staggered reveal.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        showImage = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                        showButton1 = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.15) {
                        showButton2 = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                        showButton3 = true
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
