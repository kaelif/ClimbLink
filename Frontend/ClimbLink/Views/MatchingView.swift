//
//  MatchingView.swift
//  ClimbLink
//
//  Created by Kaeli on 2025-12-03.
//

import SwiftUI

struct MatchingView: View {
    @StateObject private var viewModel = PartnerStackViewModel()
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var matches: [ClimbingPartner] = []
    @State private var showMatches = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.orange.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("ClimbLink")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button(action: {
                        showMatches.toggle()
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "heart.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                            
                            if !matches.isEmpty {
                                Text("\(matches.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(Color.blue))
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
                .padding()
                
                // Card Stack
                ZStack {
                    if viewModel.isLoading {
                        ProgressView("Finding climbers...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    await viewModel.loadStack(force: true)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if currentIndex < viewModel.partners.count {
                        ForEach(Array(viewModel.partners.enumerated()), id: \.element.id) { index, partner in
                            if index >= currentIndex && index < currentIndex + 3 {
                                SwipeableCard(
                                    partner: partner,
                                    dragOffset: index == currentIndex ? $dragOffset : .constant(.zero),
                                    rotation: index == currentIndex ? $rotation : .constant(0),
                                    onSwipe: { liked in
                                        handleSwipe(liked: liked, partner: partner)
                                    }
                                )
                                .zIndex(Double(viewModel.partners.count - index))
                                .scaleEffect(index == currentIndex ? 1.0 : 0.95 - Double(index - currentIndex) * 0.05)
                                .offset(y: CGFloat(index - currentIndex) * 10)
                            }
                        }
                    } else {
                        // No more partners
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("You've seen everyone!")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Check your matches or come back later")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Button("View Matches") {
                                showMatches.toggle()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
                
                // Action Buttons
                if currentIndex < viewModel.partners.count {
                    HStack(spacing: 40) {
                        // Pass Button
                        Button(action: {
                            swipeCard(liked: false)
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.red))
                                .shadow(radius: 5)
                        }
                        
                        // Like Button
                        Button(action: {
                            swipeCard(liked: true)
                        }) {
                            Image(systemName: "heart.fill")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.green))
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showMatches) {
            MatchesView(matches: matches)
        }
        .task {
            await viewModel.loadStack()
        }
        .onChange(of: viewModel.partners) { _ in
            currentIndex = 0
            dragOffset = .zero
            rotation = 0
        }
    }
    
    private func swipeCard(liked: Bool) {
        guard currentIndex < viewModel.partners.count else { return }
        
        let partner = viewModel.partners[currentIndex]
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: liked ? 1000 : -1000, height: 0)
            rotation = liked ? 30 : -30
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            handleSwipe(liked: liked, partner: partner)
        }
    }
    
    private func handleSwipe(liked: Bool, partner: ClimbingPartner) {
        if liked {
            // Simulate match (in real app, this would check if they also liked you)
            let didMatch = Bool.random() // Simulated match logic
            if didMatch {
                matches.append(partner)
            }
        }
        
        currentIndex += 1
        dragOffset = .zero
        rotation = 0
    }
}

