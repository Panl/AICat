//
//  ContentView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird

let mainConversation = Conversation(id: "AICat.Conversation.Main", title: "AICat Main", prompt: "")

struct ContentView: View {

    @BlackbirdLiveModels({ try await Conversation.read(from: $0, matching: \.$timeRemoved == 0, orderBy: .descending(\.$timeCreated)) }) var conversations

    @State var translationX: CGFloat = 0
    @State var showAddConversationSheet = false
    @State var conversation: Conversation?
    @AppStorage("currentChat.id") var chatId: String?
    @AppStorage("request.temperature") var temperature = 1

    @State var lastTranslationX: CGFloat = 0

    var allConversations: [Conversation] {
        [mainConversation] + conversations.results
    }

    var progress: CGFloat {
        translationX / 300
    }

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
                    withAnimation {
                        translationX = 0
                        lastTranslationX = 0
                    }
                }
            )
            if let conversation {
                ConversationView(
                    conversation: conversation,
                    onChatsClick: {
                        withAnimation {
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
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            let translationWidth = value.translation.width
                            translationX = max(min(lastTranslationX + translationWidth, 300), 0)
                        }
                        .onEnded { value in
                            let velocityX = value.predictedEndLocation.x - value.location.x
                            if velocityX > 50 {
                                withAnimation(.linear(duration: (1 - progress) * 0.35)) {
                                    translationX = 300
                                    lastTranslationX = 300
                                }
                            } else if velocityX < -50{
                                withAnimation(.linear(duration: progress * 0.35)) {
                                    translationX = 0
                                    lastTranslationX = 0
                                }
                            } else {
                                if translationX < 150 {
                                    withAnimation(.linear(duration: progress * 0.35)) {
                                        translationX = 0
                                        lastTranslationX = 0
                                    }
                                } else {
                                    withAnimation(.linear(duration: (1 - progress) * 0.35)) {
                                        translationX = 300
                                        lastTranslationX = 300
                                    }
                                }

                            }

                        }
                )
            } else {
                Color.white
            }
        }.sheet(
            isPresented: $showAddConversationSheet,
            onDismiss: {
                if conversation == nil {
                    showAddConversationSheet = true
                }
                if conversation == nil {
                    conversation = conversations.results.first
                }
            }
        ) {
            AddConversationView(
                onSave: { conversation in
                    self.conversation = conversation
                    showAddConversationSheet = false
                    chatId = conversation.id
                    withAnimation {
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
