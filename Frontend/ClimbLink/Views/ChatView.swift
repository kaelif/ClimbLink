//
//  ChatView.swift
//  ClimbLink
//
//  Created on 2025-12-08.
//

import SwiftUI

struct ChatView: View {
    let partner: ClimbingPartner
    let deviceId: String
    let partnerDeviceId: String
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    
    init(partner: ClimbingPartner, deviceId: String, partnerDeviceId: String) {
        self.partner = partner
        self.deviceId = deviceId
        self.partnerDeviceId = partnerDeviceId
        _viewModel = StateObject(wrappedValue: ChatViewModel(partner: partner, deviceId: deviceId, partnerDeviceId: partnerDeviceId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, isFromMe: message.senderDeviceId == deviceId)
                                .id(message.id)
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
            
            // Message input
            HStack(spacing: 12) {
                TextField("Type a message...", text: $viewModel.messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(partner.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadMessages()
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromMe: Bool
    
    var body: some View {
        HStack {
            if isFromMe {
                Spacer()
            }
            
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isFromMe ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromMe ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isFromMe ? .trailing : .leading)
            
            if !isFromMe {
                Spacer()
            }
        }
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var errorMessage: String?
    
    private let partner: ClimbingPartner
    private let deviceId: String
    private let partnerDeviceId: String
    private let service: MessageProviding
    
    init(partner: ClimbingPartner, deviceId: String, partnerDeviceId: String, service: MessageProviding = MessageService()) {
        self.partner = partner
        self.deviceId = deviceId
        self.partnerDeviceId = partnerDeviceId
        self.service = service
    }
    
    func loadMessages() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                messages = try await service.getMessages(deviceId1: deviceId, deviceId2: partnerDeviceId, limit: nil)
                await markAsRead()
            } catch {
                errorMessage = "Failed to load messages: \(error.localizedDescription)"
                print("Error loading messages: \(error)")
            }
        }
    }
    
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = messageText
        messageText = ""
        isSending = true
        
        Task {
            defer { isSending = false }
            
            do {
                let newMessage = try await service.sendMessage(
                    senderDeviceId: deviceId,
                    recipientDeviceId: partnerDeviceId,
                    content: content
                )
                await MainActor.run {
                    messages.append(newMessage)
                }
            } catch {
                errorMessage = "Failed to send message: \(error.localizedDescription)"
                messageText = content // Restore message on error
                print("Error sending message: \(error)")
            }
        }
    }
    
    private func markAsRead() async {
        do {
            try await service.markMessagesAsRead(deviceId: deviceId, senderDeviceId: partnerDeviceId)
        } catch {
            print("Error marking messages as read: \(error)")
        }
    }
}

