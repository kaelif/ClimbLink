//
//  ChatListView.swift
//  ClimbLink
//
//  Created by Auto on 2025-12-10.
//

import SwiftUI

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service: MessageProviding
    
    init(service: MessageProviding = MessageService()) {
        self.service = service
    }
    
    func loadConversations(deviceId: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            errorMessage = nil
            conversations = try await service.getConversations(deviceId: deviceId)
        } catch let error as MessageError {
            errorMessage = error.errorDescription ?? "Unable to load conversations. Please try again."
            conversations = []
        } catch {
            errorMessage = "Unable to load conversations: \(error.localizedDescription)"
            conversations = []
        }
    }
}

struct ChatListView: View {
    let deviceId: String
    @StateObject private var viewModel = ChatListViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading conversations...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.loadConversations(deviceId: deviceId)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.conversations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "message")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No conversations yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start a conversation from your matches!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            if let otherDeviceId = conversation.otherUserDeviceId {
                                NavigationLink(destination: ChatView(
                                    deviceId: deviceId,
                                    otherDeviceId: otherDeviceId,
                                    otherUserName: conversation.otherUserName,
                                    otherUserImage: conversation.otherUserImage
                                )) {
                                    ConversationRow(conversation: conversation)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await viewModel.loadConversations(deviceId: deviceId)
            }
        }
        .task {
            await viewModel.loadConversations(deviceId: deviceId)
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            Image(systemName: conversation.otherUserImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.blue))
                    }
                }
                
                Text(conversation.lastMessage.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(conversation.lastMessageAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

