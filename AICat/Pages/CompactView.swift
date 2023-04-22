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
    @AppStorage("currentChat.id") var chatId: String?
    @State var lastTranslationX: CGFloat = 0
    @GestureState var dragOffset: CGSize = .zero

    var progress: CGFloat {
        translationX / 300
    }

    let openDrawerDuration = 0.2

    var body: some View {
        ZStack(alignment: .topLeading) {
            ConversationListView(
                selectedChat: appStateVM.currentConversation,
                conversations: appStateVM.allConversations,
                onAddChat: {
                    showAddConversationSheet = true
                },
                onChatChanged: { chat in
                    appStateVM.setCurrentConversation(chat)
                    chatId = chat.id
                    withAnimation(.easeInOut(duration: openDrawerDuration)) {
                        translationX = 0
                        lastTranslationX = 0
                    }
                }
            ).frame(width: 300)

            ConversationView(
                store: Store(initialState: ConversationFeature.State(conversation: appStateVM.currentConversation), reducer: ConversationFeature()),
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
                    withAnimation(.easeInOut(duration: openDrawerDuration)) {
                        lastTranslationX = 0
                        translationX = 0
                    }
                }
            )
        }.onChange(of: appStateVM.allConversations) { newValue in
            let conversation = newValue.first(where: { $0.id == chatId })
            appStateVM.setCurrentConversation(conversation)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CompactView()
    }
}
