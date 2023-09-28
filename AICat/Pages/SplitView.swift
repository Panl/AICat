//
//  SplitView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/1.
//

import SwiftUI
import Combine

struct SplitView: View {
    @State var sideBarWidth: CGFloat = 300
    @State var subscription: AnyCancellable?
    @Environment(ChatStateViewModel.self) var chatState

    var size: CGSize = .zero

    var body: some View {
        HStack(spacing: 0) {
            ConversationListView(
                onChatChanged: { chat in
                    chatState.selectChat(chat)
                },
                store: chatState.chatListStore
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
                onChatsClick: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if sideBarWidth == 300 {
                            sideBarWidth = 0
                        } else {
                            sideBarWidth = 300
                        }
                    }
                },
                store: chatState.conversationStore
            )
        }.onAppear {
            chatState.fetchConversations()
            subscription = DataStore.receiveDataFromiCloud
                .receive(on: DispatchQueue.main)
                .sink {
                    chatState.fetchConversations()
                }
        }
    }
}

struct SplitView_Previews: PreviewProvider {
    static var previews: some View {
        SplitView()
            .environment(ChatListViewModel())
    }
}
