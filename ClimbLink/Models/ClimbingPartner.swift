//
//  ClimbingPartner.swift
//  ClimbLink
//
//  Created by Kaeli on 2025-12-03.
//

import Foundation

enum ClimbingType: String, CaseIterable {
    case bouldering = "Bouldering"
    case sport = "Sport Climbing"
    case trad = "Traditional"
    case indoor = "Indoor"
    case outdoor = "Outdoor"
}

enum SkillLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}

struct ClimbingPartner: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let age: Int
    let bio: String
    let skillLevel: SkillLevel
    let preferredTypes: [ClimbingType]
    let location: String
    let profileImageName: String
    let availability: String
    let favoriteCrag: String?
    
    static let samplePartners: [ClimbingPartner] = [
        ClimbingPartner(
            name: "Alex",
            age: 28,
            bio: "Love outdoor bouldering and sport climbing. Always up for a weekend adventure!",
            skillLevel: .advanced,
            preferredTypes: [.bouldering, .sport, .outdoor],
            location: "Boulder, CO",
            profileImageName: "person.circle.fill",
            availability: "Weekends",
            favoriteCrag: "Eldorado Canyon"
        ),
        ClimbingPartner(
            name: "Jordan",
            age: 32,
            bio: "Indoor climber looking to transition to outdoor. Patient and supportive partner!",
            skillLevel: .intermediate,
            preferredTypes: [.indoor, .sport],
            location: "Denver, CO",
            profileImageName: "person.circle.fill",
            availability: "Evenings & Weekends",
            favoriteCrag: nil
        ),
        ClimbingPartner(
            name: "Sam",
            age: 25,
            bio: "Trad climber with 5 years experience. Safety first, fun always!",
            skillLevel: .expert,
            preferredTypes: [.trad, .outdoor],
            location: "Golden, CO",
            profileImageName: "person.circle.fill",
            availability: "Flexible",
            favoriteCrag: "The Garden of the Gods"
        ),
        ClimbingPartner(
            name: "Casey",
            age: 29,
            bio: "Bouldering enthusiast! Love challenging problems and good vibes.",
            skillLevel: .intermediate,
            preferredTypes: [.bouldering, .indoor, .outdoor],
            location: "Fort Collins, CO",
            profileImageName: "person.circle.fill",
            availability: "Weekends",
            favoriteCrag: "Horsetooth Reservoir"
        ),
        ClimbingPartner(
            name: "Morgan",
            age: 35,
            bio: "Multi-pitch enthusiast. Looking for reliable partners for big wall adventures.",
            skillLevel: .expert,
            preferredTypes: [.trad, .sport, .outdoor],
            location: "Estes Park, CO",
            profileImageName: "person.circle.fill",
            availability: "Weekends",
            favoriteCrag: "Lumpy Ridge"
        )
    ]
}

