//
//  Message.swift
//  ClimbLink
//
//  Created by Auto on 2025-12-10.
//

import Foundation

struct Message: Identifiable, Codable, Hashable {
    let id: Int
    let senderId: Int
    let recipientId: Int
    let content: String
    let isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case recipientId = "recipient_id"
        case content
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.senderId = try container.decode(Int.self, forKey: .senderId)
        self.recipientId = try container.decode(Int.self, forKey: .recipientId)
        self.content = try container.decode(String.self, forKey: .content)
        self.isRead = try container.decode(Bool.self, forKey: .isRead)
        
        // Decode date string
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            self.createdAt = date
        } else {
            // Fallback to simpler format
            formatter.formatOptions = [.withInternetDateTime]
            self.createdAt = formatter.date(from: dateString) ?? Date()
        }
    }
}

struct Conversation: Identifiable, Codable {
    let otherUserId: Int
    let otherUserDeviceId: String?
    let otherUserName: String
    let otherUserImage: String
    let lastMessage: Message
    let unreadCount: Int
    let lastMessageAt: Date
    
    var id: Int { otherUserId }
    
    enum CodingKeys: String, CodingKey {
        case otherUserId = "other_user_id"
        case otherUserDeviceId = "other_user_device_id"
        case otherUserName = "other_user_name"
        case otherUserImage = "other_user_image"
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case lastMessageAt = "last_message_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.otherUserId = try container.decode(Int.self, forKey: .otherUserId)
        self.otherUserName = try container.decode(String.self, forKey: .otherUserName)
        self.otherUserImage = try container.decode(String.self, forKey: .otherUserImage)
        self.lastMessage = try container.decode(Message.self, forKey: .lastMessage)
        self.unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        
        // Decode date string
        let dateString = try container.decode(String.self, forKey: .lastMessageAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            self.lastMessageAt = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            self.lastMessageAt = formatter.date(from: dateString) ?? Date()
        }
    }
}

struct ConversationResponse: Decodable {
    let conversations: [Conversation]
}

struct MessagesResponse: Decodable {
    let messages: [Message]
    let currentUserId: Int
    let otherUserId: Int
}

