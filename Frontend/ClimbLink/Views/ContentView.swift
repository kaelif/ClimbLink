//
//  ContentView.swift
//  ClimbLink
//
//  Created by Kaeli on 2025-12-03.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var profileManager = ProfileManager()
    
    var body: some View {
        Group {
            if profileManager.shouldShowEditProfile {
                EditProfileView(deviceId: profileManager.deviceId)
                    .onDisappear {
                        profileManager.checkProfile()
                    }
            } else {
                MatchingView()
            }
        }
        .task {
            await profileManager.checkProfileOnLaunch()
        }
    }
}

@MainActor
class ProfileManager: ObservableObject {
    @Published var shouldShowEditProfile: Bool = false
    let deviceId: String
    
    private let service: UserProfileProviding
    private let userDefaults = UserDefaults.standard
    private let hasCheckedProfileKey = "hasCheckedProfile"
    
    init(service: UserProfileProviding = UserProfileService()) {
        self.service = service
        // Use device identifier or generate a persistent one
        if let savedDeviceId = userDefaults.string(forKey: "deviceId") {
            self.deviceId = savedDeviceId
        } else {
            self.deviceId = UIDevice.identifierForVendorString
            userDefaults.set(self.deviceId, forKey: "deviceId")
        }
    }
    
    func checkProfileOnLaunch() async {
        // Check if we've already verified the profile exists
        if userDefaults.bool(forKey: hasCheckedProfileKey) {
            // Profile already exists, don't show edit screen
            shouldShowEditProfile = false
            return
        }
        
        // First launch - get or create profile
        do {
            _ = try await service.getOrCreateProfile(deviceId: deviceId)
            // Profile exists now, mark as checked
            userDefaults.set(true, forKey: hasCheckedProfileKey)
            // For now, don't force edit on first launch
            // Later you can change this to: shouldShowEditProfile = true
            shouldShowEditProfile = false
        } catch {
            // On error, still allow app to work
            print("Error checking profile: \(error)")
            shouldShowEditProfile = false
        }
    }
    
    func checkProfile() {
        // Reset the check flag to allow re-checking
        userDefaults.set(false, forKey: hasCheckedProfileKey)
        Task {
            await checkProfileOnLaunch()
        }
    }
}

#Preview {
    ContentView()
}

