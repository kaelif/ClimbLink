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
    
    // Custom Codable implementation to handle string IDs from backend
    enum CodingKeys: String, CodingKey {
        case id, name, age, bio, skillLevel, preferredTypes, location, profileImageName, availability, favoriteCrag
    }
    
    init(id: UUID, name: String, age: Int, bio: String, skillLevel: SkillLevel, preferredTypes: [ClimbingType], location: String, profileImageName: String, availability: String, favoriteCrag: String?) {
        self.id = id
        self.name = name
        self.age = age
        self.bio = bio
        self.skillLevel = skillLevel
        self.preferredTypes = preferredTypes
        self.location = location
        self.profileImageName = profileImageName
        self.availability = availability
        self.favoriteCrag = favoriteCrag
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode id as string and convert to UUID
        let idString = try container.decode(String.self, forKey: .id)
        guard let uuid = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string: \(idString)")
        }
        self.id = uuid
        
        self.name = try container.decode(String.self, forKey: .name)
        self.age = try container.decode(Int.self, forKey: .age)
        self.bio = try container.decode(String.self, forKey: .bio)
        self.skillLevel = try container.decode(SkillLevel.self, forKey: .skillLevel)
        self.preferredTypes = try container.decode([ClimbingType].self, forKey: .preferredTypes)
        self.location = try container.decode(String.self, forKey: .location)
        self.profileImageName = try container.decode(String.self, forKey: .profileImageName)
        self.availability = try container.decode(String.self, forKey: .availability)
        self.favoriteCrag = try container.decodeIfPresent(String.self, forKey: .favoriteCrag)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(bio, forKey: .bio)
        try container.encode(skillLevel, forKey: .skillLevel)
        try container.encode(preferredTypes, forKey: .preferredTypes)
        try container.encode(location, forKey: .location)
        try container.encode(profileImageName, forKey: .profileImageName)
        try container.encode(availability, forKey: .availability)
        try container.encodeIfPresent(favoriteCrag, forKey: .favoriteCrag)
    }
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

