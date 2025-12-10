//
//  MatchesView.swift
//  ClimbLink
//
//  Created by Kaeli on 2025-12-03.
//

import SwiftUI
import UIKit

struct MatchesView: View {
    let matches: [ClimbingPartner]
    @Environment(\.dismiss) private var dismiss
    
    private func getDeviceId() -> String {
        if let saved = UserDefaults.standard.string(forKey: "deviceId") {
            return saved
        }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: "deviceId")
        return id
    }
    
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
                                MatchCard(partner: match, deviceId: getDeviceId())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Matches")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: ChatListView(deviceId: getDeviceId())) {
                        Image(systemName: "message")
                            .foregroundColor(.blue)
                    }
                }
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
    let deviceId: String
    @State private var otherDeviceId: String? = nil
    @State private var isLoadingDeviceId = false
    @State private var showChat = false
    
    private let messageService = MessageService()
    
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
            
            // Message Button
            Button(action: {
                loadDeviceIdAndShowChat()
            }) {
                if isLoadingDeviceId {
                    ProgressView()
                        .frame(width: 44, height: 44)
                } else {
                    Image(systemName: "message.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.blue))
                }
            }
            .disabled(isLoadingDeviceId)
            
            NavigationLink(destination: PartnerDetailView(partner: partner)) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .sheet(isPresented: $showChat) {
            if let otherDeviceId = otherDeviceId {
                NavigationView {
                    ChatView(
                        deviceId: deviceId,
                        otherDeviceId: otherDeviceId,
                        otherUserName: partner.name,
                        otherUserImage: partner.profileImageName
                    )
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func loadDeviceIdAndShowChat() {
        guard !isLoadingDeviceId else { return }
        isLoadingDeviceId = true
        
        Task {
            do {
                if let fetchedDeviceId = try await messageService.getDeviceId(from: partner.id) {
                    await MainActor.run {
                        self.otherDeviceId = fetchedDeviceId
                        self.isLoadingDeviceId = false
                        self.showChat = true
                    }
                } else {
                    await MainActor.run {
                        self.isLoadingDeviceId = false
                        // Show error - profile not found or no device ID
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingDeviceId = false
                    // Show error
                    print("Error loading device ID: \(error)")
                }
            }
        }
    }
}

