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
                EditProfileView(
                    deviceId: profileManager.deviceId,
                    isFirstTimeSetup: profileManager.isFirstTimeSetup,
                    onSetupComplete: {
                        profileManager.markSetupComplete()
                    }
                )
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
    @Published var isFirstTimeSetup: Bool = false
    let deviceId: String
    
    private let service: UserProfileProviding
    private let userDefaults = UserDefaults.standard
    private let hasCompletedSetupKey = "hasCompletedProfileSetup"
    
    init(service: UserProfileProviding = UserProfileService()) {
        self.service = service
        // Use device identifier or generate a persistent one
        // If cache is cleared, this will be nil and generate a new ID
        if let savedDeviceId = userDefaults.string(forKey: "deviceId") {
            self.deviceId = savedDeviceId
        } else {
            // New device or cache cleared - generate new device ID
            self.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            userDefaults.set(self.deviceId, forKey: "deviceId")
        }
    }
    
    func checkProfileOnLaunch() async {
        // Check if profile setup has been completed
        // If cache is cleared, this will be false and force setup
        if userDefaults.bool(forKey: hasCompletedSetupKey) {
            // Profile setup completed, check if profile still exists
            do {
                let profile = try await service.getOrCreateProfile(deviceId: deviceId)
                // Check if profile is still using default values (indicates it was just created)
                if profile.name == "New Climber" && profile.bio == "Just getting started with climbing!" {
                    // Profile exists but hasn't been customized - force setup
                    isFirstTimeSetup = true
                    shouldShowEditProfile = true
                } else {
                    // Profile is properly set up
                    shouldShowEditProfile = false
                }
            } catch {
                // Error fetching profile - show setup screen
                print("Error checking profile: \(error)")
                isFirstTimeSetup = true
                shouldShowEditProfile = true
            }
            return
        }
        
        // First launch or cache cleared - force profile setup
        do {
            // Get or create profile (will create with default values)
            let profile = try await service.getOrCreateProfile(deviceId: deviceId)
            // Check if it's a new profile with default values
            if profile.name == "New Climber" && profile.bio == "Just getting started with climbing!" {
                isFirstTimeSetup = true
                shouldShowEditProfile = true
            } else {
                // Profile already exists and is customized
                userDefaults.set(true, forKey: hasCompletedSetupKey)
                shouldShowEditProfile = false
            }
        } catch {
            // On error, still show setup screen
            print("Error getting/creating profile: \(error)")
            isFirstTimeSetup = true
            shouldShowEditProfile = true
        }
    }
    
    func markSetupComplete() {
        // Mark that profile setup has been completed
        userDefaults.set(true, forKey: hasCompletedSetupKey)
        isFirstTimeSetup = false
        shouldShowEditProfile = false
    }
    
    func checkProfile() {
        // Reset the setup flag to allow re-checking
        userDefaults.set(false, forKey: hasCompletedSetupKey)
        Task {
            await checkProfileOnLaunch()
        }
    }
}

#Preview {
    ContentView()
}

