//
//  PartnerDetailView.swift
//  ClimbLink
//
//  Created by Kaeli on 2025-12-03.
//

import SwiftUI

struct PartnerDetailView: View {
    let partner: ClimbingPartner
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile Image
                    Image(systemName: partner.profileImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Name and Age
                        Text("\(partner.name), \(partner.age)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Location
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(partner.location)
                                .font(.headline)
                        }
                        
                        Divider()
                        
                        // Bio
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)
                            Text(partner.bio)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Skill Level
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Skill Level")
                                .font(.headline)
                            Text(partner.skillLevel.rawValue)
                                .font(.body)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.2))
                                )
                                .foregroundColor(.blue)
                        }
                        
                        Divider()
                        
                        // Climbing Types
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preferred Climbing Types")
                                .font(.headline)
                            WrappingHStack(items: partner.preferredTypes) { type in
                                Text(type.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.2))
                                    )
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Divider()
                        
                        // Availability
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Availability")
                                .font(.headline)
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text(partner.availability)
                                    .font(.body)
                            }
                        }
                        
                        if let favoriteCrag = partner.favoriteCrag {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Favorite Crag")
                                    .font(.headline)
                                HStack(spacing: 4) {
                                    Image(systemName: "mountain.2.fill")
                                        .foregroundColor(.blue)
                                    Text(favoriteCrag)
                                        .font(.body)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Helper view for wrapping tags
struct WrappingHStack<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    let spacing: CGFloat = 8
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geometry.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        if item == items.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

