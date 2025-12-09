//
//  SwipeService.swift
//  ClimbLink
//
//  Created on 2025-12-08.
//

import Foundation

protocol SwipeProviding {
    func recordSwipe(swiperDeviceId: String, swipedProfileId: UUID, action: SwipeAction) async throws
}

enum SwipeAction: String, Codable {
    case like = "like"
    case pass = "pass"
}

struct SwipeService: SwipeProviding {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL = URL(string: "http://localhost:4000")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func recordSwipe(swiperDeviceId: String, swipedProfileId: UUID, action: SwipeAction) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("swipes"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        let body: [String: Any] = [
            "swiperDeviceId": swiperDeviceId,
            "swipedProfileId": swipedProfileId.uuidString,
            "action": action.rawValue
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}

