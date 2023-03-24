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

    @State var translationX: CGFloat = 0
    @State var showAddConversationSheet = false
    @State var conversation: Conversation = mainConversation
    @AppStorage("currentChat.id") var chatId: String?

    @State var lastTranslationX: CGFloat = 0
    @GestureState var dragOffset: CGSize = .zero

    var allConversations: [Conversation] {
        [mainConversation] + conversations.results
    }

    var progress: CGFloat {
        translationX / 300
    }

    let openDrawerDuration = 0.2

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
                    withAnimation(.easeInOut(duration: openDrawerDuration)) {
                        translationX = 0
                        lastTranslationX = 0
                    }
                }
            ).frame(width: 300)

            ConversationView(
                conversation: conversation,
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
                Color.white
                    .ignoresSafeArea()
                    .clipShape(RoundedRectangle(cornerRadius: 12 * progress))
                    .shadow(color: Color.black.opacity(0.1).opacity(progress), radius: 4)
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
                        guard (value.translation.width > 0 && value.startLocation.x < 80)
                                || (value.translation.width < 0 && value.startLocation.x > getScreenSize().width - 300) else { return }
                        state = value.translation
                    }
                    /// .onEnded will not called when gesture cancelled by the scrollview
                    .onEnded { value in
                        print("gesture end")
                        guard (value.translation.width > 0 && value.startLocation.x < 80)
                                || (value.translation.width < 0 && value.startLocation.x > getScreenSize().width - 300) else { return }
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
                onSave: { conversation in
                    self.conversation = conversation
                    showAddConversationSheet = false
                    chatId = conversation.id
                    withAnimation(.easeInOut(duration: openDrawerDuration)) {
                        lastTranslationX = 0
                        translationX = 0
                    }
                }
            )
        }.onChange(of: conversations) { newValue in
            conversation = newValue.results.first(where: { $0.id == chatId }) ?? mainConversation
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
