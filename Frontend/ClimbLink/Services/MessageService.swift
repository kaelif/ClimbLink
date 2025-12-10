//
//  MessageService.swift
//  ClimbLink
//
//  Created by Auto on 2025-12-10.
//

import Foundation

enum MessageError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case timeout
    case connectionFailed
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error (code: \(code))"
        case .serverError(let message):
            return "Server error: \(message)"
        case .timeout:
            return "Request timed out. Check your connection."
        case .connectionFailed:
            return "Cannot connect to server. Make sure the backend is running."
        case .unknown(let message):
            return "Error: \(message)"
        }
    }
}

protocol MessageProviding {
    func sendMessage(senderDeviceId: String, recipientDeviceId: String, content: String) async throws -> Message
    func getConversation(deviceId1: String, deviceId2: String) async throws -> (messages: [Message], currentUserId: Int, otherUserId: Int)
    func getConversations(deviceId: String) async throws -> [Conversation]
    func markMessagesAsRead(deviceId: String, otherDeviceId: String) async throws -> Int
    func getDeviceId(from profileId: UUID) async throws -> String?
}

struct MessageService: MessageProviding {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL = URL(string: "http://localhost:4000")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func sendMessage(senderDeviceId: String, recipientDeviceId: String, content: String) async throws -> Message {
        let url = baseURL.appendingPathComponent("messages")
        var request = URLRequest(url: url)
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
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MessageError.invalidResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorData["message"] {
                    throw MessageError.serverError(message)
                }
                throw MessageError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Message.self, from: data)
        } catch let error as MessageError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw MessageError.timeout
            } else if (error as NSError).code == NSURLErrorCannotConnectToHost {
                throw MessageError.connectionFailed
            }
            throw MessageError.unknown(error.localizedDescription)
        }
    }
    
    func getConversation(deviceId1: String, deviceId2: String) async throws -> (messages: [Message], currentUserId: Int, otherUserId: Int) {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("messages/conversation"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "deviceId1", value: deviceId1),
            URLQueryItem(name: "deviceId2", value: deviceId2)
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MessageError.invalidResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorData["message"] {
                    throw MessageError.serverError(message)
                }
                throw MessageError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(MessagesResponse.self, from: data)
            return (messages: response.messages, currentUserId: response.currentUserId, otherUserId: response.otherUserId)
        } catch let error as MessageError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw MessageError.timeout
            } else if (error as NSError).code == NSURLErrorCannotConnectToHost {
                throw MessageError.connectionFailed
            }
            throw MessageError.unknown(error.localizedDescription)
        }
    }
    
    func getConversations(deviceId: String) async throws -> [Conversation] {
        let url = baseURL.appendingPathComponent("messages/conversations/\(deviceId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MessageError.invalidResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorData["message"] {
                    throw MessageError.serverError(message)
                }
                throw MessageError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(ConversationResponse.self, from: data).conversations
        } catch let error as MessageError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw MessageError.timeout
            } else if (error as NSError).code == NSURLErrorCannotConnectToHost {
                throw MessageError.connectionFailed
            }
            throw MessageError.unknown(error.localizedDescription)
        }
    }
    
    func markMessagesAsRead(deviceId: String, otherDeviceId: String) async throws -> Int {
        let url = baseURL.appendingPathComponent("messages/read")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        let body: [String: Any] = [
            "deviceId": deviceId,
            "otherDeviceId": otherDeviceId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MessageError.invalidResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorData["message"] {
                    throw MessageError.serverError(message)
                }
                throw MessageError.httpError(httpResponse.statusCode)
            }
            
            let result = try JSONDecoder().decode([String: Int].self, from: data)
            return result["count"] ?? 0
        } catch let error as MessageError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw MessageError.timeout
            } else if (error as NSError).code == NSURLErrorCannotConnectToHost {
                throw MessageError.connectionFailed
            }
            throw MessageError.unknown(error.localizedDescription)
        }
    }
    
    func getDeviceId(from profileId: UUID) async throws -> String? {
        let url = baseURL.appendingPathComponent("profile/\(profileId.uuidString)/deviceId")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MessageError.invalidResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                if httpResponse.statusCode == 404 {
                    return nil // Profile not found
                }
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorData["message"] {
                    throw MessageError.serverError(message)
                }
                throw MessageError.httpError(httpResponse.statusCode)
            }
            
            let result = try JSONDecoder().decode([String: String?].self, from: data)
            return result["deviceId"] ?? nil
        } catch let error as MessageError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw MessageError.timeout
            } else if (error as NSError).code == NSURLErrorCannotConnectToHost {
                throw MessageError.connectionFailed
            }
            throw MessageError.unknown(error.localizedDescription)
        }
    }
}

