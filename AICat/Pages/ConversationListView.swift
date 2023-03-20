//
//  ConversationListView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import SwiftUI

struct ConversationListView: View {
    let selectedChat: Conversation?
    let conversations: [Conversation]
    let onAddChat: () -> Void
    let onChatChanged: (Conversation) -> Void

    var body: some View {
        VStack {
            Image(systemName: "timelapse")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .padding(.top, 32)
            Spacer().frame(height: 32)
            HStack {
                Text("Chats")
                    .font(.custom("Avenir Next", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                Spacer()
            }
            ScrollView {
                LazyVStack {
                    ForEach(conversations) { conversation in
                        Button(action: { onChatChanged(conversation) }) {
                            HStack {
                                Image(systemName: "bubble.left")
                                    .aspectRatio(contentMode: .fit)
                                Text(conversation.title)
                                    .font(.custom("Avenir Next", size: 16))
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Spacer()
                                if selectedChat?.id == conversation.id {
                                    Circle()
                                        .frame(width: 10, height: 10)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.black.opacity(0.8), .black.opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing)
                                        )
                                }
                            }
                            .padding(.vertical, 8)
                        }.tint(.black)
                    }
                    Button(action: onAddChat) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .aspectRatio(contentMode: .fit)
                            Text("New Chat")
                                .font(.custom("Avenir Next", size: 16))
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }.tint(.gray)
                }
            }
            Spacer()
            Button(action: {}) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clean Chats")
                        .font(.custom("Avenir Next", size: 16))
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 10)
            }.tint(.gray)
            Button(action: {}) {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Help")
                        .font(.custom("Avenir Next", size: 16))
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 10)
            }.tint(.gray)
            Button(action: {}) {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings")
                        .font(.custom("Avenir Next", size: 16))
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 10)
            }.tint(.gray)
            Spacer().frame(height: 56)
        }
        .padding(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
        .frame(width: 300)
        .ignoresSafeArea(.keyboard)
    }
}

struct ConversationListView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationListView(
            selectedChat: nil,
            conversations: [Conversation(title: "How to make a gift", prompt: "")],
            onAddChat: {}, onChatChanged: { _ in }
        )
    }
}
