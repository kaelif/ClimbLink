//
//  UserProfileService.swift
//  ClimbLink
//
//  Created on 2025-12-08.
//

import Foundation
import UIKit

enum UserProfileError: LocalizedError {
    case connectionError(String)
    case serverError(statusCode: Int, message: String)
    case decodingError(DecodingError)
    case invalidResponse
    case databaseSchemaError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .connectionError(let message):
            return "Cannot connect to server: \(message). Make sure the backend is running on port 4000."
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .databaseSchemaError(let message):
            return message
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

protocol UserProfileProviding {
    func getOrCreateProfile(deviceId: String) async throws -> UserProfile
    func updateProfile(deviceId: String, profile: UserProfile) async throws -> UserProfile
}

struct UserProfileService: UserProfileProviding {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL = URL(string: "http://localhost:4000")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func getOrCreateProfile(deviceId: String) async throws -> UserProfile {
        var request = URLRequest(url: baseURL.appendingPathComponent("user/profile/\(deviceId)"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserProfileError.invalidResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                if errorMessage.contains("device_id") {
                    throw UserProfileError.databaseSchemaError("The database is missing the 'device_id' column. Please run the migration SQL in Supabase.")
                }
                throw UserProfileError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(UserProfile.self, from: data)
        } catch let error as UserProfileError {
            throw error
        } catch let decodingError as DecodingError {
            throw UserProfileError.decodingError(decodingError)
        } catch {
            if (error as NSError).code == NSURLErrorCannotConnectToHost ||
               (error as NSError).code == NSURLErrorNetworkConnectionLost ||
               (error as NSError).code == NSURLErrorTimedOut {
                throw UserProfileError.connectionError(error.localizedDescription)
            }
            throw UserProfileError.unknown(error.localizedDescription)
        }
    }
    
    func updateProfile(deviceId: String, profile: UserProfile) async throws -> UserProfile {
        var request = URLRequest(url: baseURL.appendingPathComponent("user/profile/\(deviceId)"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(profile)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(UserProfile.self, from: data)
    }
}

// Device ID helper
extension UIDevice {
    static var identifierForVendorString: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}

