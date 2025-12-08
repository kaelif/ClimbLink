//
//  ClimbingPartnerService.swift
//  ClimbLink
//
//  Created by Kaeli on 2025-12-04.
//

import Foundation

struct PartnerStackResponse: Decodable {
    let stack: [ClimbingPartner]
    let count: Int
}

enum ClimbingPartnerError: LocalizedError {
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

protocol ClimbingPartnerProviding {
    func fetchStack() async throws -> [ClimbingPartner]
}

struct ClimbingPartnerService: ClimbingPartnerProviding {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL = URL(string: "http://localhost:4000")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func fetchStack() async throws -> [ClimbingPartner] {
        var request = URLRequest(url: baseURL.appendingPathComponent("getStack"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClimbingPartnerError.invalidResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                // Try to decode error message from backend
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorData["message"] {
                    throw ClimbingPartnerError.serverError(message)
                }
                throw ClimbingPartnerError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(PartnerStackResponse.self, from: data).stack
        } catch let error as ClimbingPartnerError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw ClimbingPartnerError.timeout
            } else if (error as NSError).code == NSURLErrorCannotConnectToHost {
                throw ClimbingPartnerError.connectionFailed
            }
            throw ClimbingPartnerError.unknown(error.localizedDescription)
        }
    }
}

@MainActor
final class PartnerStackViewModel: ObservableObject {
    @Published private(set) var partners: [ClimbingPartner] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service: ClimbingPartnerProviding
    
    init(service: ClimbingPartnerProviding = ClimbingPartnerService()) {
        self.service = service
    }
    
    func loadStack(force: Bool = false) async {
        guard !isLoading else { return }
        if partners.isEmpty || force {
            isLoading = true
            defer { isLoading = false }
            
            do {
                errorMessage = nil
                partners = try await service.fetchStack()
            } catch let error as ClimbingPartnerError {
                errorMessage = error.errorDescription ?? "Unable to load partners. Please try again."
                partners = []
            } catch {
                errorMessage = "Unable to load partners: \(error.localizedDescription)"
                partners = []
            }
        }
    }
}

