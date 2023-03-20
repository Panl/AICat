//
//  ConversationView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird
import Alamofire

struct ConversationView: View {
    @State var inputText: String = ""
    @State var messages: [ChatMessage] = []
    let conversation: Conversation
    @State var isSending = false
    @State var error: AFError?

    let onChatsClick: () -> Void

    @Environment(\.blackbirdDatabase) var db

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                HStack {
                    Button(action: onChatsClick) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .tint(.black)
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        Text(conversation.title)
                            .font(.custom("Avenir Next", size: 16))
                            .fontWeight(.bold)
                            .lineLimit(1)
                        Text(conversation.prompt)
                            .font(.custom("Avenir Next", size: 12))
                            .fontWeight(.medium)
                            .opacity(0.2)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "ellipsis")
                }
                .padding(.horizontal, 20)
                .frame(height: 44)
                Spacer(minLength: 0)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        Spacer().frame(height: 4)
                        ForEach(messages, id: \.id) { message in
                            if message.role == "user" {
                                MineMessageView(text: message.content)
                            } else {
                                AICatMessageView(text: LocalizedStringKey(stringLiteral: message.content.trimmingCharacters(in: .whitespacesAndNewlines)))
                            }
                        }
                        if let error {
                            ErrorMessageView(errorMessage: error.localizedDescription) {
                                retryComplete()
                            }
                        }
                        Spacer().frame(height: 80)
                    }
                }
                .scrollIndicators(.hidden)
            }
            HStack {
                TextField(text: $inputText) {
                    Text("Say someting")
                        .font(.custom("Avenir Next", size: 16))
                        .fontWeight(.medium)
                }
                .tint(.black)
                .submitLabel(.send)
                .onSubmit {
                    completeMessage()
                }
                .font(.custom("Avenir Next", size: 16))
                .fontWeight(.medium)
                if isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 28, height: 28)
                } else {
                    Button(
                        action: {
                            completeMessage()
                        }
                    ) {
                        Image(systemName: "paperplane.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .tint(
                                LinearGradient(
                                    colors: [.black.opacity(0.9), .black.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                    }
                    .disabled(inputText.isEmpty)
                }

            }
            .frame(height: 56)
            .padding(.leading, 20)
            .padding(.trailing, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }.onAppear {
            queryMessages(cid: conversation.id)
        }.onChange(of: conversation) { newValue in
            queryMessages(cid: newValue.id)
        }
    }

    func queryMessages(cid: String) {
        Task {
            guard let db else { return }
            messages = (try! await ChatMessage.read(from: db, matching: \.$conversationId == cid, orderBy: .ascending(\.$timeCreated)))
        }
    }

    func completeMessage() {
        guard !inputText.isEmpty else { return }
        isSending = true
        let sendText = inputText
        inputText = ""
        let messagesToSend = messages.suffix(4).map({ Message(role: $0.role, content: $0.content) }) + [Message(role: "user", content: sendText)]
        Task {
            let chatMessage = ChatMessage(role: "user", content: sendText, conversationId: conversation.id)
            await db?.upsert(model: chatMessage)
            queryMessages(cid: conversation.id)
            let result = await CatApi.complete(messages: messagesToSend, with: conversation.prompt)
            switch result {
            case .success(let success):
                saveMessage(response: success)
            case .failure(let failure):
                error = failure
                print("\(failure)")
            }
            isSending = false
        }
    }

    func retryComplete() {
        error = nil
        isSending = true
        let messagesToSend = messages.suffix(4).map({ Message(role: $0.role, content: $0.content) })
        Task {
            let result = await CatApi.complete(messages: messagesToSend, with: conversation.prompt)
            switch result {
            case .success(let success):
                saveMessage(response: success)
            case .failure(let failure):
                error = failure
                print("\(failure)")
            }
            isSending = false
        }
    }

    func saveMessage(response: CompleteResponse) {
        if let message = response.choices.first?.message {
            let chatMessage = ChatMessage(role: message.role, content: message.content, conversationId: conversation.id)
            Task {
                await db?.upsert(model: chatMessage)
                queryMessages(cid: conversation.id)
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
            conversation: Conversation(title: "Mini Chat", prompt: ""),
            onChatsClick: { }

        )
    }
}

struct MineMessageView: View {
    let text: String
    var body: some View {
        ZStack {
            HStack {
                Spacer(minLength: 40)
                Text(text)
                    .tint(.teal)
                    .font(.custom("Avenir Next", size: 16))
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
                    .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topLeft]))
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
                .font(.custom("Avenir Next", size: 16))
                .fontWeight(.medium)
                .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                .background(Color.gray.opacity(0.05))
                .clipShape(CornerRadiusShape(radius: 4, corners: .topLeft))
                .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topRight]))
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

struct ErrorMessageView: View {
    let errorMessage: String
    let retry: () -> Void
    var body: some View {
        ZStack {
            HStack {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .font(.custom("Avenir Next", size: 16))
                    .fontWeight(.medium)
                    .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Button(
                    action: retry
                ) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .tint(
                                LinearGradient(
                                    colors: [.black.opacity(0.9), .black.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                    }
            }.padding(.horizontal, 20)
        }
    }
}
