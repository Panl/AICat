//
//  ContentView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird

let mainConversation = Conversation(id: "AICat.Conversation.Main", title: "AICat Main", prompt: "")

struct ContentView: View {

    @BlackbirdLiveModels({ try await Conversation.read(from: $0, matching: \.$timeRemoved == 0, orderBy: .descending(\.$timeCreated)) }) var conversations

    @State var showConversation = false
    @State var showAddConversationSheet = false
    @State var conversation: Conversation?
    @AppStorage("currentChat.id") var chatId: String?
    @AppStorage("request.temperature") var temperature = 1

    var allConversations: [Conversation] {
        [mainConversation] + conversations.results
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ConversationListView(
                selectedChat: conversation,
                conversations: allConversations,
                onAddChat: {
                    showAddConversationSheet = true
                },
                onChatChanged: { chat in
                    conversation = chat
                    chatId = chat.id
                    withAnimation {
                        showConversation = false
                    }
                }
            )
            if let conversation {
                ConversationView(
                    conversation: conversation,
                    onChatsClick: {
                        withAnimation {
                            showConversation.toggle()
                        }
                    }
                )
                .background {
                    Color.white
                        .ignoresSafeArea(.keyboard)
                        .clipShape(RoundedRectangle(cornerRadius: showConversation ? 8 : 0))
                        .shadow(color: showConversation ? Color.black.opacity(0.1) : .clear, radius: 4)
                }
                .scaleEffect(showConversation ? CGSize(width: 0.95, height: 0.95) : CGSize(width: 1, height: 1))
                .offset(showConversation ? .init(width: 300, height: 0) : .init(width: 0, height: 0))
            } else {
                Color.white
            }
        }.sheet(
            isPresented: $showAddConversationSheet,
            onDismiss: {
                if conversation == nil {
                    showAddConversationSheet = true
                }
                if conversation == nil {
                    conversation = conversations.results.first
                }
            }
        ) {
            AddConversationView(
                onSave: { conversation in
                    self.conversation = conversation
                    showAddConversationSheet = false
                    chatId = conversation.id
                    withAnimation {
                        showConversation = false
                    }
                }
            )
        }.onChange(of: conversations) { newValue in
            if newValue.results.isEmpty {
                showAddConversationSheet = true
            }
            conversation = newValue.results.first(where: { $0.id == chatId }) ?? mainConversation
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
