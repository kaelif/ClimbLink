//
//  EditProfileView.swift
//  ClimbLink
//
//  Created on 2025-12-08.
//

import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel: EditProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    let isFirstTimeSetup: Bool
    let onSetupComplete: () -> Void
    
    init(deviceId: String, isFirstTimeSetup: Bool = false, onSetupComplete: @escaping () -> Void = {}) {
        self.isFirstTimeSetup = isFirstTimeSetup
        self.onSetupComplete = onSetupComplete
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(deviceId: deviceId))
    }
    
    var body: some View {
        NavigationView {
            Form {
                if isFirstTimeSetup {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome to ClimbLink! 🧗")
                                .font(.headline)
                            Text("Let's set up your profile so other climbers can find you.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $viewModel.name)
                    Stepper("Age: \(viewModel.age)", value: $viewModel.age, in: 18...100)
                    TextField("Location", text: $viewModel.location)
                }
                
                Section(header: Text("About")) {
                    TextEditor(text: $viewModel.bio)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Climbing Details")) {
                    Picker("Skill Level", selection: $viewModel.skillLevel) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    
                    TextField("Availability", text: $viewModel.availability)
                    TextField("Favorite Crag (optional)", text: Binding(
                        get: { viewModel.favoriteCrag ?? "" },
                        set: { viewModel.favoriteCrag = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section(header: Text("Climbing Types")) {
                    ForEach(ClimbingType.allCases, id: \.self) { type in
                        Toggle(type.rawValue, isOn: Binding(
                            get: { viewModel.preferredTypes.contains(type) },
                            set: { isOn in
                                if isOn {
                                    viewModel.preferredTypes.append(type)
                                } else {
                                    viewModel.preferredTypes.removeAll { $0 == type }
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle(isFirstTimeSetup ? "Set Up Your Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Only show cancel button if not first time setup
                if !isFirstTimeSetup {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isFirstTimeSetup ? "Continue" : "Save") {
                        Task {
                            await viewModel.saveProfile()
                            if !viewModel.isLoading && viewModel.errorMessage == nil {
                                if isFirstTimeSetup {
                                    onSetupComplete()
                                }
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .interactiveDismissDisabled(isFirstTimeSetup) // Prevent swipe to dismiss on first setup
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }
}

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 25
    @Published var bio: String = ""
    @Published var skillLevel: SkillLevel = .beginner
    @Published var preferredTypes: [ClimbingType] = []
    @Published var location: String = ""
    @Published var availability: String = "Flexible"
    @Published var favoriteCrag: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let deviceId: String
    private let service: UserProfileProviding
    
    init(deviceId: String, service: UserProfileProviding = UserProfileService()) {
        self.deviceId = deviceId
        self.service = service
    }
    
    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            errorMessage = nil
            let profile = try await service.getOrCreateProfile(deviceId: deviceId)
            
            name = profile.name
            age = profile.age
            bio = profile.bio
            skillLevel = profile.skillLevel
            preferredTypes = profile.preferredTypes
            location = profile.location
            availability = profile.availability
            favoriteCrag = profile.favoriteCrag
        } catch let error as UserProfileError {
            errorMessage = error.errorDescription ?? "Failed to load profile"
            print("Error loading profile: \(error)")
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            print("Unexpected error: \(error)")
        }
    }
    
    func saveProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            errorMessage = nil
            
            let profile = UserProfile(
                id: UUID(), // This will be ignored by backend, deviceId is used
                name: name,
                age: age,
                bio: bio,
                skillLevel: skillLevel,
                preferredTypes: preferredTypes.isEmpty ? [.indoor] : preferredTypes,
                location: location.isEmpty ? "Unknown" : location,
                profileImageName: "person.circle.fill",
                availability: availability.isEmpty ? "Flexible" : availability,
                favoriteCrag: favoriteCrag
            )
            
            _ = try await service.updateProfile(deviceId: deviceId, profile: profile)
        } catch let error as UserProfileError {
            errorMessage = error.errorDescription ?? "Failed to save profile"
            print("Error saving profile: \(error)")
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            print("Unexpected error: \(error)")
        }
    }
}

#Preview {
    EditProfileView(deviceId: "test-device-id")
}

