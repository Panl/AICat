//
//  ConversationView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird

struct ConversationView: View {
    @State var inputText: String = ""
    @State var messages: [ChatMessage] = []
    let conversation: Conversation
    @State var isSending = false

    @Environment(\.blackbirdDatabase) var db

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Spacer()
                    Text(conversation.title)
                        .font(.custom("Avenir", size: 16))
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "ellipsis")
                }
                .padding(.horizontal, 20)
                .frame(height: 44)
                Spacer(minLength: 0)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(messages, id: \.id) { message in
                            if message.role == "user" {
                                MineMessageView(text: message.content)
                            } else {
                                AICatMessageView(text: LocalizedStringKey(stringLiteral: message.content.trimmingCharacters(in: .whitespacesAndNewlines)))
                            }
                        }
                        Spacer().frame(height: 80)
                    }
                }
            }
            HStack {
                TextField(text: $inputText) {
                    Text("hello")
                }
                if isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 24, height: 24)
                } else {
                    Button(
                        action: {
                            completeMessage()
                        }
                    ) {
                        Image(systemName: "paperplane")
                    }
                }

            }
            .frame(height: 56)
            .padding(.horizontal, 20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }.onAppear {
            queryMessages()
        }
    }

    func queryMessages() {
        Task {
            guard let db else { return }
            messages = (try! await ChatMessage.read(from: db, matching: \.$conversationId == conversation.id, orderBy: .ascending(\.$timeCreated)))
            print("--message-count: \(messages.count)")
        }
    }

    func completeMessage() {
        isSending = true
        let sendText = inputText
        inputText = ""
        let chatMessage = ChatMessage(role: "user", content: sendText, conversationId: conversation.id)
        Task {
            if let db {
                try! await chatMessage.write(to: db)
                queryMessages()
            }
            let result = await CatApi.complete(content: sendText)
            switch result {
            case .success(let success):
                saveMessage(response: success)
            case .failure(let failure):
                print("\(failure)")
            }
            isSending = false
        }
    }

    func saveMessage(response: CompleteResponse) {
        if let message = response.choices.first?.message {
            let chatMessage = ChatMessage(role: message.role, content: message.content, conversationId: conversation.id)
            if let db {
                Task {
                    try! await chatMessage.write(to: db)
                    queryMessages()
                }
            }
        }
    }
}

struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationView(
            messages: [
                ChatMessage(role: "user", content: "hello hello hello hello hello hello hello hello hello hello hello hello hello hello hello", conversationId: ""),
                ChatMessage(role: "other", content: "hello hello hello hello hello hello hello hello hello hello hello hello hello hello hello hello hello hello hello hello", conversationId: "")
            ],
            conversation: Conversation(title: "Hello", prompt: "")

        )
    }
}

struct MineMessageView: View {
    let text: String
    var body: some View {
        ZStack {
            HStack {
                Spacer(minLength: 80)
                Text(text)
                    .tint(.teal)
                    .font(.custom("Avenir", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.8), .black.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .clipShape(CornerRadiusShape(radius: 4, corners: .topRight))
                    .clipShape(CornerRadiusShape(radius: 16, corners: [.bottomLeft, .bottomRight, .topLeft]))
                    .padding(.trailing, 20)
            }
        }
    }
}

struct AICatMessageView: View {
    let text: LocalizedStringKey
    var body: some View {
        ZStack {
            Text(text)
                .font(.custom("Avenir", size: 14))
                .fontWeight(.medium)
                .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                .background(Color.gray.opacity(0.05))
                .clipShape(CornerRadiusShape(radius: 4, corners: .topLeft))
                .clipShape(CornerRadiusShape(radius: 16, corners: [.bottomLeft, .bottomRight, .topRight]))
                .padding(.init(top: 0, leading: 20, bottom: 0, trailing: 36))
        }
    }
}

struct CornerRadiusShape: Shape {
    var radius = CGFloat.infinity
    var corners = UIRectCorner.allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
