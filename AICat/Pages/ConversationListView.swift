//
//  ConversationListView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import SwiftUI

struct ConversationListView: View {
    let selectedChat: Conversation?
    let conversations: [Conversation]
    let onAddChat: () -> Void
    let onChatChanged: (Conversation) -> Void

    @Environment(\.blackbirdDatabase) var db
    @State var showClearAllChatAlert = false
    @State var showSettingsView = false

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "timelapse")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .padding(.top, 32)
            Spacer().frame(height: 32)
            HStack {
                Text("Chats")
                    .font(.manrope(size: 18, weight: .semibold))
                    .foregroundColor(.blackText.opacity(0.4))
                Spacer()
            }.padding(.leading, 20)
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    Spacer().frame(height: 10)
                    ForEach(conversations) { conversation in
                        Button(action: { onChatChanged(conversation) }) {
                            HStack {
                                Image(systemName: conversation == mainConversation ? "command" : "bubble.left" )
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20)
                                Text(conversation.title)
                                    .lineLimit(1)
                                    .font(.manrope(size: 16, weight: conversation == selectedChat ? .semibold : .medium))
                                    .foregroundColor(conversation == selectedChat ? .blackText : .blackText.opacity(0.7))
                                Spacer()
                                if selectedChat?.id == conversation.id {
                                    Circle()
                                        .frame(width: 10, height: 10)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.primary.opacity(0.8), .primary.opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing)
                                        )
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .tint(conversation == selectedChat ? .primary : .primary.opacity(0.7))
                        .contextMenu {
                            if conversation != mainConversation {
                                Button(role: .destructive, action: { deleteConversation(conversation) }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .padding(.horizontal, 8)

                    }
                    Button(action: onAddChat) {
                        HStack {
                            Image(systemName: "plus.bubble")
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20)
                            Text("New Chat")
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    }
                    .padding(.horizontal, 8)
                    .tint(.blackText.opacity(0.5))
                }
            }
            Spacer(minLength: 20)
            Button(action: { showClearAllChatAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clean Chats")
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .tint(.blackText.opacity(0.5))
            .padding(.horizontal, 20)
            .alert("Are you sure to clean all chats", isPresented: $showClearAllChatAlert) {
                Button("Sure", role: .destructive) {
                    clearAllConversation()
                }
                Button("Cancel", role: .cancel) {
                    showClearAllChatAlert = false
                }
            }
            Link(destination: URL(string: "https://help.openai.com/en/collections/3742473-chatgpt")!) {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Help")
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .padding(.horizontal, 20)
            .tint(.blackText.opacity(0.5))
            Button(action: { showSettingsView = true }) {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings")
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .padding(.horizontal, 20)
            .tint(.blackText.opacity(0.5))
            Spacer().frame(height: 32)
        }
        .fullScreenCover(isPresented: $showSettingsView) {
            SettingsView {
                showSettingsView = false
            }
        }
        .ignoresSafeArea(.keyboard)
        .font(.manrope(size: 16, weight: .medium))
    }

    func deleteConversation(_ conversation: Conversation) {
        Task {
            var c = conversation
            c.timeRemoved = Date.now.timeInSecond
            await db?.upsert(model: c)
        }
    }

    func clearAllConversation() {
        Task {
            for var c in conversations {
                c.timeRemoved = Date.now.timeInSecond
                await db?.upsert(model: c)
            }
        }
    }
}

struct ConversationListView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationListView(
            selectedChat: mainConversation,
            conversations: [mainConversation, Conversation(title: "How to make a gift", prompt: "")],
            onAddChat: {}, onChatChanged: { _ in }
        )
    }
}
