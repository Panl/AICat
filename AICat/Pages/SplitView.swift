//
//  SplitView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/1.
//

import SwiftUI
import ComposableArchitecture

struct SplitView: View {
    @State var sideBarWidth: CGFloat = 300

    var size: CGSize = .zero

    let store: StoreOf<AppReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            HStack(spacing: 0) {
                ConversationListView(
                    onChatChanged: { chat in
                        viewStore.send(.selectChat(chat))
                    },
                    store: store.scope(state: \.conversationList, action: AppReducer.Action.conversationListAction)
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
                    store: store.scope(state: \.conversationMessages, action: AppReducer.Action.conversationMessagesAction),
                    onChatsClick: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            if sideBarWidth == 300 {
                                sideBarWidth = 0
                            } else {
                                sideBarWidth = 300
                            }
                        }
                    }
                )
            }.onAppear {
                viewStore.send(.queryConversations)
            }
        }
    }
}

struct SplitView_Previews: PreviewProvider {
    static var previews: some View {
        SplitView(store: Store(initialState: AppReducer.State(), reducer: AppReducer()))
    }
}
