//
//  MainView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/24.
//

import SwiftUI
import Blackbird

let mainConversation = Conversation(id: "AICat.Conversation.Main", title: "AICat Main", prompt: "")

struct MainView: View {
    
    @BlackbirdLiveModels({ try await Conversation.read(from: $0, matching: \.$timeRemoved == 0, orderBy: .descending(\.$timeCreated)) }) var conversations
    @State var showAddConversationSheet = false
    @State var conversation: Conversation = mainConversation
    @AppStorage("currentChat.id") var chatId: String?
    @State var sideBarWidth: CGFloat = 300

    var allConversations: [Conversation] {
        [mainConversation] + conversations.results
    }


    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > 560 {
                HStack(spacing: 0) {
                    ConversationListView(
                        selectedChat: conversation,
                        conversations: allConversations,
                        onAddChat: {
                            showAddConversationSheet = true
                        },
                        onChatChanged: { chat in
                            conversation = chat
                            chatId = chat.id
                        }
                    )
                    .frame(idealWidth: 300, idealHeight: proxy.size.height)
                    .fixedSize()
                    .frame(width: sideBarWidth)
                    .clipped()
                    Rectangle()
                        .frame(width: 1, height: proxy.size.height)
                        .foregroundColor(.gray.opacity(0.2))
                        .opacity(sideBarWidth == 300 ? 1 : 0)
                    ConversationView(
                        conversation: conversation,
                        onChatsClick: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                if sideBarWidth == 300 {
                                    sideBarWidth = 0
                                } else {
                                    sideBarWidth = 300
                                }
                            }
                        }
                    ).sheet(
                        isPresented: $showAddConversationSheet,
                        onDismiss: {}
                    ) {
                        AddConversationView(
                            onSave: { conversation in
                                self.conversation = conversation
                                showAddConversationSheet = false
                                chatId = conversation.id
                            }
                        )
                    }.onChange(of: conversations) { newValue in
                        conversation = newValue.results.first(where: { $0.id == chatId }) ?? mainConversation
                    }
                }
            } else {
                ContentView()
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
