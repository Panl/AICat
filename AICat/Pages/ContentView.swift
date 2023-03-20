//
//  ContentView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird

struct ContentView: View {

    @BlackbirdLiveModels({ try await Conversation.read(from: $0, matching: \.$timeRemoved == 0, orderBy: .descending(\.$timeCreated)) }) var conversations

    @State var showConversation = false
    @State var showAddConversationSheet = false
    @State var conversation: Conversation?
    @AppStorage("currentChat.id") var chatId: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            ConversationListView(
                selectedChat: conversation,
                conversations: conversations.results,
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
                .background(showConversation ? Color(red: 0.95, green: 0.95, blue: 0.95) : .white)
                .scaleEffect(showConversation ? CGSize(width: 0.95, height: 0.95) : CGSize(width: 1, height: 1))
                .offset(showConversation ? .init(width: 300, height: 0) : .init(width: 0, height: 0))
            } else {
                Color.white
            }
        }.sheet(
            isPresented: $showAddConversationSheet,
            onDismiss: {
                if conversations.results.isEmpty {
                    showAddConversationSheet = true
                }
                if conversation == nil {
                    conversation = conversations.results.first
                }
            }
        ) {
            AddConversationView(
                onSave: { conversation in
                    showAddConversationSheet = false
                    self.conversation = conversation
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
            conversation = newValue.results.first(where: { $0.id == chatId }) ?? conversations.results.first
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
