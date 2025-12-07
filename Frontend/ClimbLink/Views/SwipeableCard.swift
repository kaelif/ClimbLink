//
//  SwipeableCard.swift
//  ClimbLink
//
//  Created by Kaeli on 2025-12-03.
//

import SwiftUI

struct SwipeableCard: View {
    let partner: ClimbingPartner
    @Binding var dragOffset: CGSize
    @Binding var rotation: Double
    let onSwipe: (Bool) -> Void // true for like, false for pass
    
    @State private var showDetails = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 0) {
                    // Profile Image
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: partner.profileImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Skill Level Badge
                        VStack {
                            HStack {
                                Spacer()
                                Text(partner.skillLevel.rawValue)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.8))
                                    )
                                    .padding(.trailing, 16)
                                    .padding(.top, 16)
                            }
                            Spacer()
                        }
                    }
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        // Name and Age
                        HStack {
                            Text("\(partner.name), \(partner.age)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                showDetails.toggle()
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Location
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(partner.location)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Bio
                        Text(partner.bio)
                            .font(.body)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        // Climbing Types
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(partner.preferredTypes, id: \.self) { type in
                                    Text(type.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(Color.orange.opacity(0.2))
                                        )
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        // Availability
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(partner.availability)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                }
            }
            .rotationEffect(.degrees(rotation))
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        rotation = Double(value.translation.width / 10)
                    }
                    .onEnded { value in
                        let swipeThreshold: CGFloat = 100
                        
                        if abs(value.translation.width) > swipeThreshold {
                            // Swipe left (pass) or right (like)
                            let liked = value.translation.width > 0
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = CGSize(
                                    width: value.translation.width > 0 ? 1000 : -1000,
                                    height: value.translation.height
                                )
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipe(liked)
                            }
                        } else {
                            // Snap back
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = .zero
                                rotation = 0
                            }
                        }
                    }
            )
            .sheet(isPresented: $showDetails) {
                PartnerDetailView(partner: partner)
            }
        }
    }
}

