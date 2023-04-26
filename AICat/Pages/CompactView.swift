//
//  ContentView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird
import ComposableArchitecture

struct CompactView: View {

    @EnvironmentObject var appStateVM: AICatStateViewModel

    @State var translationX: CGFloat = 0
    @State var showAddConversationSheet = false
    @State var lastTranslationX: CGFloat = 0
    @GestureState var dragOffset: CGSize = .zero

    var progress: CGFloat {
        translationX / 300
    }

    let openDrawerDuration = 0.2

    let store: StoreOf<AppReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack(alignment: .topLeading) {
                ConversationListView(
                    onAddChat: {
                        showAddConversationSheet = true
                    },
                    onChatChanged: { chat in
                        viewStore.send(.selectChat(chat))
                        withAnimation(.easeInOut(duration: openDrawerDuration)) {
                            translationX = 0
                            lastTranslationX = 0
                        }
                    },
                    store: store.scope(state: \.conversationList, action: AppReducer.Action.conversationListAction)
                ).frame(width: 300)

                ConversationView(
                    store: store.scope(state: \.conversationMessages, action: AppReducer.Action.conversationMessagesAction),
                    onChatsClick: {
                        withAnimation(.easeInOut(duration: openDrawerDuration)) {
                            if lastTranslationX == 300 {
                                translationX = 0
                                lastTranslationX = 0
                            } else {
                                translationX = 300
                                lastTranslationX = 300
                            }
                        }
                    }
                )
                .background {
                    Color.background
                        .clipShape(RoundedRectangle(cornerRadius: 12 * progress))
                        .shadow(color: .primaryColor.opacity(0.1).opacity(progress), radius: 4)
                }
                .scaleEffect(x: 1 - progress * 0.05, y: 1 - progress * 0.05)
                .offset(x: translationX, y: 0)
                .onChange(of: $dragOffset.wrappedValue) { newValue in
                    translationX = max(min(lastTranslationX + newValue.width, 300), 0)
                }
                .simultaneousGesture(
                    DragGesture()
                        /// .updateing with GesturesState automatically sets the offset to isInitial position
                        .updating($dragOffset) { value, state, transaction in
                            state = value.translation
                        }
                        /// .onEnded will not called when gesture cancelled by the scrollview
                        .onEnded { value in
                            let velocityX = value.predictedEndLocation.x - value.location.x
                            if velocityX > 50 {
                                withAnimation(.linear(duration: (1 - progress) * openDrawerDuration)) {
                                    translationX = 300
                                    lastTranslationX = 300
                                }
                            } else if velocityX < -50{
                                withAnimation(.linear(duration: progress * openDrawerDuration)) {
                                    translationX = 0
                                    lastTranslationX = 0
                                }
                            } else {
                                if translationX < 150 {
                                    withAnimation(.linear(duration: progress * openDrawerDuration)) {
                                        translationX = 0
                                        lastTranslationX = 0
                                    }
                                } else {
                                    withAnimation(.linear(duration: (1 - progress) * openDrawerDuration)) {
                                        translationX = 300
                                        lastTranslationX = 300
                                    }
                                }

                            }

                        }
                )
            }.sheet(
                isPresented: $showAddConversationSheet,
                onDismiss: {}
            ) {
                AddConversationView(
                    onClose: {
                        showAddConversationSheet = false
                    }
                )
            }.onAppear {
                viewStore.send(.queryConversations)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CompactView(store: Store(initialState: AppReducer.State(), reducer: AppReducer()))
    }
}
