//
//  MatchesView.swift
//  ClimbLink
//
//  Created by Kaeli on 2025-12-03.
//

import SwiftUI

struct MatchesView: View {
    let matches: [ClimbingPartner]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if matches.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No matches yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Keep swiping to find your climbing partner!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(matches) { match in
                                NavigationLink(destination: PartnerDetailView(partner: match)) {
                                    MatchCard(partner: match)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Matches")
            .navigationBarTitleDisplayMode(.large)
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

struct MatchCard: View {
    let partner: ClimbingPartner
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            Image(systemName: partner.profileImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text("\(partner.name), \(partner.age)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(partner.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text(partner.skillLevel.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.2))
                        )
                        .foregroundColor(.blue)
                    
                    if !partner.preferredTypes.isEmpty {
                        Text(partner.preferredTypes[0].rawValue)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}


