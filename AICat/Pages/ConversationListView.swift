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

    @EnvironmentObject var appStateVM: AICatStateViewModel
    @State var showClearAllChatAlert = false
    @State var showSettingsView = false

    var premiumText: String {
        if appStateVM.isPremium {
            return "AICat Premium"
        } else {
            return "AICat Premium(\(appStateVM.sentMessageCount)/\(appStateVM.freeMessageCount))"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Image("chatgpt_logo")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .padding(.top, 32)
                .foregroundColor(.primaryColor)
            Spacer().frame(height: 32)
            HStack {
                Text("Conversations".uppercased())
                    .font(.manrope(size: 14, weight: .semibold))
                    .foregroundColor(.blackText.opacity(0.4))
                Spacer()
            }.padding(.leading, 20)
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    Spacer().frame(height: 10)
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
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 8)
                    .tint(.blackText.opacity(0.5))
                    ForEach(conversations) { conversation in
                        Button(action: { onChatChanged(conversation) }) {
                            HStack {
                                Image(systemName: conversation.isMain ? "command" : "bubble.left" )
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
                        .tint(conversation == selectedChat ? .primaryColor : .primaryColor.opacity(0.7))
                        .contextMenu {
                            if !conversation.isMain {
                                Button(role: .destructive, action: { deleteConversation(conversation) }) {
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
                Button(action: { showClearAllChatAlert = true }) {
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
                .alert("Are you sure to clear all conversations", isPresented: $showClearAllChatAlert) {
                    Button("Sure", role: .destructive) {
                        clearAllConversation()
                    }
                    Button("Cancel", role: .cancel) {
                        showClearAllChatAlert = false
                    }
                }
                if appStateVM.developMode {
                    Button(action: { appStateVM.showAddAPIKeySheet = true }) {
                        HStack {
                            Image(systemName: "key.viewfinder")
                            Text("OpenAI API Key")
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderless)
                    .tint(.blackText.opacity(0.5))
                    .padding(.horizontal, 20)
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
                if !appStateVM.developMode {
                    Button(
                        action: { appStateVM.showPremumPage = true }
                    ) {
                        HStack {
                            Image(systemName: "crown")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            Text(premiumText)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 20)
                    .tint(.blackText.opacity(0.5))
                }
                #if os(iOS)
                Button(action: { showSettingsView = true }) {
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
                .fullScreenCover(isPresented: $showSettingsView) {
                    SettingsView {
                        showSettingsView = false
                    }
                }
                #endif
            }
            Spacer().frame(height: 16)
        }
        .ignoresSafeArea(.keyboard)
        .font(.manrope(size: 16, weight: .medium))
    }

    func deleteConversation(_ conversation: Conversation) {
        Task {
            var c = conversation
            c.timeRemoved = Date.now.timeInSecond
            await appStateVM.saveConversation(c)
        }
    }

    func clearAllConversation() {
        Task {
            for var c in conversations {
                c.timeRemoved = Date.now.timeInSecond
                await appStateVM.saveConversation(c)
            }
        }
    }
}

struct ConversationListView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationListView(
            selectedChat: Conversation(title: "Main", prompt: ""),
            conversations: [Conversation(title: "Main", prompt: ""), Conversation(title: "How to make a gift", prompt: "")],
            onAddChat: {}, onChatChanged: { _ in }
        ).environmentObject(AICatStateViewModel())
    }
}
