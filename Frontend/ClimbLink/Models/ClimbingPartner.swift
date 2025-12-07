//
//  ClimbingPartner.swift
//  ClimbLink
//
//  Created by Kaeli on 2025-12-03.
//

import Foundation

enum ClimbingType: String, CaseIterable, Codable {
    case bouldering = "Bouldering"
    case sport = "Sport Climbing"
    case trad = "Traditional"
    case indoor = "Indoor"
    case outdoor = "Outdoor"
}

enum SkillLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}

struct ClimbingPartner: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let age: Int
    let bio: String
    let skillLevel: SkillLevel
    let preferredTypes: [ClimbingType]
    let location: String
    let profileImageName: String
    let availability: String
    let favoriteCrag: String?
}

extension ClimbingPartner {
    static let previewStack: [ClimbingPartner] = [
        ClimbingPartner(
            id: UUID(),
            name: "Alex",
            age: 28,
            bio: "Love outdoor bouldering and sport climbing. Always up for a weekend adventure!",
            skillLevel: .advanced,
            preferredTypes: [.bouldering, .sport, .outdoor],
            location: "Boulder, CO",
            profileImageName: "person.circle.fill",
            availability: "Weekends",
            favoriteCrag: "Eldorado Canyon"
        )
    ]
}

