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
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PartnerStackResponse.self, from: data).stack
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
            } catch {
                errorMessage = "Unable to load partners. Please try again."
                partners = []
            }
        }
    }
}

