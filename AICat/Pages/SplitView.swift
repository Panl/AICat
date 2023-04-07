//
//  SplitView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/1.
//

import SwiftUI

struct SplitView: View {
    @EnvironmentObject var appStateVM: AICatStateViewModel
    @State var showAddConversationSheet = false
    @AppStorage("currentChat.id") var chatId: String?
    @State var sideBarWidth: CGFloat = 300

    var size: CGSize = .zero

    var body: some View {
        HStack(spacing: 0) {
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
            .frame(idealWidth: 300, idealHeight: size.height)
            .fixedSize()
            .frame(width: sideBarWidth)
            .clipped()
            Rectangle()
                .frame(width: 1)
                .foregroundColor(.gray.opacity(0.2))
                .opacity(sideBarWidth == 300 ? 1 : 0)
            ConversationView(
                conversation: appStateVM.currentConversation,
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
                    onClose: {
                        showAddConversationSheet = false
                    }
                )
            }.onChange(of: appStateVM.allConversations) { newValue in
                let conversation = newValue.first(where: { $0.id == chatId })
                appStateVM.setCurrentConversation(conversation)
            }
        }
    }
}

struct SplitView_Previews: PreviewProvider {
    static var previews: some View {
        SplitView()
    }
}
