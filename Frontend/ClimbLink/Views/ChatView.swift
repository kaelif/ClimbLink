//
//  ChatView.swift
//  ClimbLink
//
//  Created by Auto on 2025-12-10.
//

import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSending = false
    @Published var currentUserId: Int? = nil
    
    private let service: MessageProviding
    private let currentDeviceId: String
    
    init(service: MessageProviding = MessageService(), currentDeviceId: String) {
        self.service = service
        self.currentDeviceId = currentDeviceId
    }
    
    func loadMessages(deviceId1: String, deviceId2: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            errorMessage = nil
            let result = try await service.getConversation(deviceId1: deviceId1, deviceId2: deviceId2)
            messages = result.messages
            
            // Set current user ID based on which deviceId matches currentDeviceId
            if deviceId1 == currentDeviceId {
                currentUserId = result.currentUserId
            } else if deviceId2 == currentDeviceId {
                currentUserId = result.otherUserId
            }
        } catch let error as MessageError {
            errorMessage = error.errorDescription ?? "Unable to load messages. Please try again."
            messages = []
        } catch {
            errorMessage = "Unable to load messages: \(error.localizedDescription)"
            messages = []
        }
    }
    
    func sendMessage(senderDeviceId: String, recipientDeviceId: String, content: String) async {
        guard !isSending && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        defer { isSending = false }
        
        do {
            let newMessage = try await service.sendMessage(
                senderDeviceId: senderDeviceId,
                recipientDeviceId: recipientDeviceId,
                content: content.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            messages.append(newMessage)
            // Mark messages as read when sending
            _ = try? await service.markMessagesAsRead(deviceId: senderDeviceId, otherDeviceId: recipientDeviceId)
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
    }
    
    func markAsRead(deviceId: String, otherDeviceId: String) async {
        do {
            _ = try await service.markMessagesAsRead(deviceId: deviceId, otherDeviceId: otherDeviceId)
            // Reload messages to get updated read status
            await loadMessages(deviceId1: deviceId, deviceId2: otherDeviceId)
        } catch {
            // Silently fail - not critical
            print("Failed to mark messages as read: \(error)")
        }
    }
}

struct ChatView: View {
    let deviceId: String
    let otherDeviceId: String
    let otherUserName: String
    let otherUserImage: String
    
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    init(deviceId: String, otherDeviceId: String, otherUserName: String, otherUserImage: String) {
        self.deviceId = deviceId
        self.otherDeviceId = otherDeviceId
        self.otherUserName = otherUserName
        self.otherUserImage = otherUserImage
        _viewModel = StateObject(wrappedValue: ChatViewModel(currentDeviceId: deviceId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 8) {
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button("Retry") {
                                    Task {
                                        await viewModel.loadMessages(deviceId1: deviceId, deviceId2: otherDeviceId)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                        } else {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: viewModel.currentUserId != nil ? message.senderId == viewModel.currentUserId : false
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Message Input
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    if viewModel.isSending {
                        ProgressView()
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
            .padding()
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMessages(deviceId1: deviceId, deviceId2: otherDeviceId)
            await viewModel.markAsRead(deviceId: deviceId, otherDeviceId: otherDeviceId)
        }
        .onAppear {
            // Refresh messages when view appears
            Task {
                await viewModel.loadMessages(deviceId1: deviceId, deviceId2: otherDeviceId)
            }
        }
    }
    
    private func sendMessage() {
        let text = messageText
        messageText = ""
        isInputFocused = false
        
        Task {
            await viewModel.sendMessage(
                senderDeviceId: deviceId,
                recipientDeviceId: otherDeviceId,
                content: text
            )
        }
    }
    
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
}

