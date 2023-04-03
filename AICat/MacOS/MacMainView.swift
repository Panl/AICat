//
//  MacMainView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/3.
//

import SwiftUI

struct MacMainView: View {
    @EnvironmentObject var appStateVM: AICatStateViewModel
    @State var showAddConversationSheet = false
    @AppStorage("currentChat.id") var chatId: String?

    var chatTitle: String {
        appStateVM.currentConversation.title
    }

    var chatPrompt: String {
        appStateVM.currentConversation.prompt
    }

    var body: some View {
        NavigationSplitView(
            sidebar: {
                ConversationListView(
                    selectedChat: appStateVM.currentConversation,
                    conversations: appStateVM.allConversations,
                    onAddChat: {
                        showAddConversationSheet = true
                    },
                    onChatChanged: { chat in
                        appStateVM.setCurrentConversation(chat)
                        chatId = chat.id
                    }
                )
            },
            detail: {
                ConversationView(
                    conversation: appStateVM.currentConversation,
                    showToolbar: false,
                    onChatsClick: {
                        
                    }
                ).sheet(
                    isPresented: $showAddConversationSheet,
                    onDismiss: {}
                ) {
                    AddConversationView(
                        onSave: { conversation in
                            appStateVM.setCurrentConversation(conversation)
                            showAddConversationSheet = false
                            chatId = conversation.id
                        }
                    )
                }.onChange(of: appStateVM.conversations) { newValue in
                    let conversation = newValue.first(where: { $0.id == chatId }) ?? mainConversation
                    appStateVM.setCurrentConversation(conversation)
                }
                .navigationTitle(chatTitle)
                .navigationSubtitle(chatPrompt)
                .toolbar {
                    Image(systemName: "ellipsis")
                        .frame(width: 24, height: 24)
                        .clipShape(Rectangle())
                }
            }
        ).navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 320)
    }
}

struct MacMainView_Previews: PreviewProvider {
    static var previews: some View {
        MacMainView()
    }
}
