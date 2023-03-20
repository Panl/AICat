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
    @State var showAddConversation = false
    @State var showClearMesssageAlert = false
    @State var isAIGenerating = false

    let onChatsClick: () -> Void

    @Environment(\.blackbirdDatabase) var db

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                HStack(spacing: 18) {
                    Button(action: onChatsClick) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .tint(.black)
                            .frame(width: 24, height: 24)
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        Text(conversation.title)
                            .font(.custom("Avenir Next", size: 16))
                            .fontWeight(.bold)
                            .lineLimit(1)
                        Text(conversation.prompt)
                            .font(.custom("Avenir Next", size: 12))
                            .fontWeight(.regular)
                            .opacity(0.2)
                            .lineLimit(1)
                    }
                    Spacer()
                    Menu {
                        Button(action: editConversation) {
                            Label("Edit Chat", systemImage: "square.and.pencil")
                        }
                        Button(role: .destructive, action: { showClearMesssageAlert = true }) {
                            Label("Clean Messages", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 24, height: 24)
                            .clipShape(Rectangle())
                    }
                    .alert("Are you sure to clean all messages?", isPresented: $showClearMesssageAlert) {
                        Button("Clear", role: .destructive) {
                            cleanMessages()
                        }
                        Button("Cancel", role: .cancel) {
                            showClearMesssageAlert = false
                        }
                    }
                    .tint(.black)
                }
                .padding(.horizontal, 20)
                .frame(height: 44)
                Spacer(minLength: 0)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            Spacer().frame(height: 4)
                                .id("Top")
                            ForEach(messages, id: \.id) { message in
                                MessageView(message: message)
                                    .contextMenu {
                                        Button(action: { UIPasteboard.general.string = message.content }) {
                                            Label("Copy", systemImage: "doc.on.doc")
                                        }
                                        Button(role: .destructive, action: { deleteMessage(message) }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }.id(message.id)
                            }
                            if let error {
                                ErrorMessageView(errorMessage: error.localizedDescription) {
                                    retryComplete()
                                }.id("error")
                            }
                            if isAIGenerating && isSending {
                                InputingMessageView().id("generating")
                            }
                            Spacer().frame(height: 80)
                                .id("Bottom")
                        }
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: messages) { newMessages in
                        proxy.scrollTo("Bottom")
                    }
                    .onChange(of: isAIGenerating) { _ in
                        proxy.scrollTo("Bottom")
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
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
        }.sheet(isPresented: $showAddConversation) {
            AddConversationView(conversation: conversation) { _ in
                showAddConversation = false
            }
        }
    }

    func editConversation() {
        showAddConversation = true
    }

    func cleanMessages() {
        let timeRemoved = Date.now.timeInSecond
        Task {
            for var message in messages {
                message.timeRemoved = timeRemoved
                await db?.upsert(model: message)
            }
            queryMessages(cid: conversation.id)
        }
    }

    func deleteMessage(_ message: ChatMessage) {
        Task {
            var messageToRemove = message
            messageToRemove.timeRemoved = Date.now.timeInSecond
            await db?.upsert(model: messageToRemove)
            queryMessages(cid: conversation.id)
        }
    }

    func queryMessages(cid: String) {
        Task {
            guard let db else { return }
            messages = (try! await ChatMessage.read(from: db, matching: \.$conversationId == cid && \.$timeRemoved == 0, orderBy: .ascending(\.$timeCreated)))
        }
    }

    func completeMessage() {
        guard !inputText.isEmpty else { return }
        isSending = true
        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            if isSending {
                isAIGenerating = true
            }
        }
        let sendText = inputText
        inputText = ""
        let messagesToSend = messages.suffix(4).map({ Message(role: $0.role, content: $0.content) }) + [Message(role: "user", content: sendText)]
        Task {
            let chatMessage = ChatMessage(role: "user", content: sendText, conversationId: conversation.id)
            await db?.upsert(model: chatMessage)
            queryMessages(cid: conversation.id)
            await completeMessages(messagesToSend)
        }
    }

    func retryComplete() {
        error = nil
        isSending = true
        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            if isSending {
                isAIGenerating = true
            }
        }
        let messagesToSend = messages.suffix(4).map({ Message(role: $0.role, content: $0.content) })
        Task {
            await completeMessages(messagesToSend)
        }
    }

    func completeMessages(_ messages: [Message]) async {
        let result = await CatApi.complete(messages: messages, with: conversation.prompt)
        switch result {
        case .success(let success):
            saveMessage(response: success)
        case .failure(let failure):
            error = failure
            print("\(failure)")
        }
        isSending = false
        isAIGenerating = false
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
            conversation: Conversation(title: "Mini Chat", prompt: "hello hello hello hello hello hello hello hello hello hello "),
            onChatsClick: { }

        )
    }
}

struct MineMessageView: View {
    let message: ChatMessage
    var body: some View {
        ZStack {
            HStack {
                Spacer(minLength: 40)
                Text(message.content)
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
    let message: ChatMessage
    var body: some View {
        ZStack {
            Text(LocalizedStringKey(message.content))
                .font(.custom("Avenir Next", size: 16))
                .fontWeight(.medium)
                .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                .clipShape(CornerRadiusShape(radius: 4, corners: .topLeft))
                .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topRight]))
                .padding(.init(top: 0, leading: 20, bottom: 0, trailing: 36))
        }
    }
}

struct MessageView: View {
    let message: ChatMessage
    var body: some View {
        if message.role == "user" {
            MineMessageView(message: message)
        } else {
            AICatMessageView(message: message)
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

struct InputingMessageView: View {
    @State private var shouldAnimate = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.black)
                .frame(width: 10, height: 10)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever(), value: shouldAnimate)
            Circle()
                .fill(Color.black)
                .frame(width: 10, height: 10)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.3), value: shouldAnimate)
            Circle()
                .fill(Color.black)
                .frame(width: 10, height: 10)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.6), value: shouldAnimate)
        }
        .padding(EdgeInsets.init(top: 10, leading: 20, bottom: 10, trailing: 20))
        .frame(height: 40)
        .background(Color(red: 0.96, green: 0.96, blue: 0.98))
        .clipShape(CornerRadiusShape(radius: 4, corners: .topLeft))
        .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topRight]))
        .padding(.init(top: 0, leading: 20, bottom: 0, trailing: 36))
        .onAppear {
            self.shouldAnimate = true
        }
    }
}
