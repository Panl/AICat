//
//  ConversationListView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import SwiftUI
import ApphudSDK

@Observable
class ChatListViewModel {
    var selectedChat: Conversation = mainConversation
    var chats: [Conversation] = []
    var showClearAllChatsAlert = false
    var showSettingsView = false
    var showPremiumPage = false
    var showAddConversation = false
}

struct ConversationListView: View {
    let onChatChanged: (Conversation) -> Void
    @State var viewStore: ChatListViewModel
    @Environment(ChatStateViewModel.self) var chatState

    init(onChatChanged: @escaping (Conversation) -> Void, store: ChatListViewModel) {
        self.onChatChanged = onChatChanged
        self.viewStore = store
    }

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "timelapse")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .padding(.top, 32)
            Spacer().frame(height: 32)
            HStack {
                Text("CONVERSATIONS")
                    .font(.manrope(size: 14, weight: .semibold))
                    .foregroundColor(.blackText.opacity(0.4))
                Spacer()
            }.padding(.leading, 20)
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    Spacer().frame(height: 10)
                    Button(action: { viewStore.showAddConversation = true }) {
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
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 8)
                    .tint(.blackText.opacity(0.5))
                    ForEach(viewStore.chats) { conversation in
                        Button(action: { onChatChanged(conversation) }) {
                            HStack {
                                Image(systemName: conversation.isMain ? "command" : "bubble.left" )
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20)
                                Text(conversation.title)
                                    .lineLimit(1)
                                    .font(.manrope(size: 16, weight: conversation == viewStore.selectedChat ? .semibold : .medium))
                                    .foregroundColor(conversation == viewStore.selectedChat ? .blackText : .blackText.opacity(0.7))
                                Spacer()
                                if viewStore.selectedChat == conversation {
                                    Circle()
                                        .frame(width: 10, height: 10)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.primaryColor.opacity(0.8), .primaryColor.opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing)
                                        )
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.borderless)
                        .tint(conversation == viewStore.selectedChat ? .primaryColor : .primaryColor.opacity(0.7))
                        .contextMenu {
                            if !conversation.isMain {
                                Button(role: .destructive, action: {
                                    chatState.deleteChat(conversation)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .padding(.horizontal, 8)

                    }
                }
            }
            RoundedRectangle(cornerRadius: 0.5)
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.1))
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            VStack(spacing: 0) {
                Button(action: { viewStore.showClearAllChatsAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Conversations")
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderless)
                .tint(.blackText.opacity(0.5))
                .padding(.horizontal, 20)
                .alert("Are you sure to clear all conversations", isPresented: $viewStore.showClearAllChatsAlert) {
                    Button("Sure", role: .destructive) {
                        let conversations = viewStore.chats.filter { !$0.isMain }
                        chatState.clearChats(conversations)
                    }
                    Button("Cancel", role: .cancel) {
                        viewStore.showClearAllChatsAlert = false
                    }
                }
                Button(action: {
                    #if os(iOS)
                    UIApplication.shared.open(URL(string: "https://help.openai.com/en/collections/3742473-chatgpt")!)
                    #elseif os(macOS)
                    NSWorkspace.shared.open(URL(string: "https://help.openai.com/en/collections/3742473-chatgpt")!)
                    #endif
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Updates & FAQ")
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 20)
                .tint(.blackText.opacity(0.5))
                Button(
                    action: { viewStore.showPremiumPage = true }
                ) {
                    HStack {
                        Image(systemName: "crown")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                        Text("AICat Premium")
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 20)
                .tint(.blackText.opacity(0.5))
                #if os(iOS)
                Button(action: { viewStore.showSettingsView = true }) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Settings")
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 20)
                .tint(.blackText.opacity(0.5))
                .fullScreenCover(isPresented: $viewStore.showSettingsView) {
                    SettingsView {
                        viewStore.showSettingsView = false
                    }
                }
                #endif
            }
            Spacer().frame(height: 16)
        }
        .ignoresSafeArea(.keyboard)
        .font(.manrope(size: 16, weight: .medium))
        .sheet(isPresented: $viewStore.showPremiumPage) {
            PremiumPage(
                onClose: { viewStore.showPremiumPage = false }
            )
        }
        .sheet(
            isPresented: $viewStore.showAddConversation,
            onDismiss: {
                viewStore.showAddConversation = false
            }
        ) {
            AddConversationView(
                onClose: {
                    viewStore.showAddConversation = false
                },
                onSave: { chat in
                    chatState.saveChat(chat)
                    viewStore.showAddConversation = false
                }
            )
        }
    }
}

struct ConversationListView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationListView(
            onChatChanged: { _ in },
            store: ChatListViewModel()
        )
    }
}
