//
//  ContentView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird
import Combine

struct CompactView: View {
    @State var translationX: CGFloat = 0
    @State var showAddConversationSheet = false
    @State var lastTranslationX: CGFloat = 0
    @GestureState var dragOffset: CGSize = .zero
    @State var subscription: AnyCancellable?
    @Environment(ChatStateViewModel.self) var chatState

    var progress: CGFloat {
        translationX / 300
    }

    let openDrawerDuration = 0.2

    var body: some View {
        ZStack(alignment: .topLeading) {
            ConversationListView(
                onChatChanged: { chat in
                    chatState.selectChat(chat)
                    withAnimation(.easeInOut(duration: openDrawerDuration)) {
                        translationX = 0
                        lastTranslationX = 0
                    }
                },
                store: chatState.chatListStore
            ).frame(width: 300)

            ConversationView(
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
                },
                store: chatState.conversationStore
            )
            .background {
                Color.background
                    .clipShape(RoundedRectangle(cornerRadius: 12 * progress))
                    .shadow(color: .primaryColor.opacity(0.1).opacity(progress), radius: 4)
            }
            .scaleEffect(x: 1 - progress * 0.05, y: 1 - progress * 0.05)
            .offset(x: translationX, y: 0)
            .onChange(of: $dragOffset.wrappedValue) { _, newValue in
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CompactView()
            .environment(ChatStateViewModel())
    }
}
