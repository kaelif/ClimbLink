//
//  MessageService.swift
//  ClimbLink
//
//  Created on 2025-12-08.
//

import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let senderDeviceId: String
    let recipientDeviceId: String
    let content: String
    let createdAt: Date
    let readAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderDeviceId = "sender_device_id"
        case recipientDeviceId = "recipient_device_id"
        case content
        case createdAt = "created_at"
        case readAt = "read_at"
    }
}

struct Conversation: Identifiable {
    let id: String // partnerDeviceId
    let partner: ClimbingPartner
    let lastMessage: LastMessage
    let unreadCount: Int
}

struct LastMessage: Codable {
    let id: UUID
    let content: String
    let createdAt: String
    let isFromMe: Bool
    let readAt: String?
}

protocol MessageProviding {
    func getMatches(deviceId: String) async throws -> [ClimbingPartner]
    func sendMessage(senderDeviceId: String, recipientDeviceId: String, content: String) async throws -> Message
    func getMessages(deviceId1: String, deviceId2: String, limit: Int?) async throws -> [Message]
    func getConversations(deviceId: String) async throws -> [Conversation]
    func markMessagesAsRead(deviceId: String, senderDeviceId: String) async throws
}

struct MessageService: MessageProviding {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL = URL(string: "http://localhost:4000")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func getMatches(deviceId: String) async throws -> [ClimbingPartner] {
        var request = URLRequest(url: baseURL.appendingPathComponent("matches/\(deviceId)"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([ClimbingPartner].self, from: data)
    }
    
    func sendMessage(senderDeviceId: String, recipientDeviceId: String, content: String) async throws -> Message {
        var request = URLRequest(url: baseURL.appendingPathComponent("messages"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        let body: [String: Any] = [
            "senderDeviceId": senderDeviceId,
            "recipientDeviceId": recipientDeviceId,
            "content": content
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        return try decoder.decode(Message.self, from: data)
    }
    
    func getMessages(deviceId1: String, deviceId2: String, limit: Int? = nil) async throws -> [Message] {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("messages/\(deviceId1)/\(deviceId2)"), resolvingAgainstBaseURL: false)!
        if let limit = limit {
            urlComponents.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        return try decoder.decode([Message].self, from: data)
    }
    
    func getConversations(deviceId: String) async throws -> [Conversation] {
        var request = URLRequest(url: baseURL.appendingPathComponent("conversations/\(deviceId)"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        struct ConversationResponse: Codable {
            let partnerDeviceId: String
            let partnerProfile: ClimbingPartner?
            let lastMessage: LastMessage
            let unreadCount: Int
        }
        
        let responses = try decoder.decode([ConversationResponse].self, from: data)
        return responses.compactMap { response in
            guard let partner = response.partnerProfile else { return nil }
            return Conversation(
                id: response.partnerDeviceId,
                partner: partner,
                lastMessage: response.lastMessage,
                unreadCount: response.unreadCount
            )
        }
    }
    
    func markMessagesAsRead(deviceId: String, senderDeviceId: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("messages/read/\(deviceId)/\(senderDeviceId)"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}

