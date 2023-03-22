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
    @State var showCommands = false
    @AppStorage("request.context.messages") var contextCount: Int = 0
    @State var commnadCardHeight: CGFloat = 0
    @FocusState var isFocused: Bool

    @BlackbirdLiveModels({ try await Conversation.read(from: $0, matching: \.$timeRemoved == 0, orderBy: .descending(\.$timeCreated)) }) var conversations

    var filterdPrompts: [Conversation] {
        let query = inputText.lowercased().trimmingCharacters(in: ["/"])
        return conversations.results.filter { !$0.prompt.isEmpty }.filter { $0.title.lowercased().contains(query) || $0.prompt.lowercased().contains(query) || query.isEmpty }
    }

    @State var selectedPrompt: Conversation?

    var promptText: String {
        selectedPrompt?.prompt ?? conversation.prompt
    }

    let onChatsClick: () -> Void

    @Environment(\.blackbirdDatabase) var db

    init(messages: [ChatMessage] = [], conversation: Conversation, onChatsClick: @escaping () -> Void) {
        self.conversation = conversation
        self.onChatsClick = onChatsClick
        self.messages = messages
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                HStack(spacing: 18) {
                    Button(action: {
                        isFocused = false
                        onChatsClick()
                    }) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .tint(.black)
                            .frame(width: 24, height: 24)
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        Text(conversation.title)
                            .font(.manrope(size: 16, weight: .heavy))
                            .lineLimit(1)
                        if !promptText.isEmpty {
                            Text(promptText)
                                .font(.manrope(size: 12, weight: .medium))
                                .opacity(0.4)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Menu {
                        if conversation != mainConversation {
                            Button(action: editConversation) {
                                Label("Edit Chat", systemImage: "square.and.pencil")
                            }
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
                        Button("Sure", role: .destructive) {
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
                    ScrollView(showsIndicators: false) {
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
                            Spacer().frame(height: 100)
                                .id("Bottom")
                        }
                    }
                    .gesture(DragGesture().onChanged { _ in
                        self.endEditing(force: true)
                    })
                    .onChange(of: messages) { newMessages in
                        proxy.scrollTo("Bottom")
                    }
                    .onChange(of: isAIGenerating) { _ in
                        proxy.scrollTo("Bottom")
                    }
                }
            }
            VStack {
                if showCommands, !filterdPrompts.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 4)
                            ForEach(filterdPrompts) { prompt in
                                Button(action: {
                                    selectedPrompt = prompt
                                    inputText = ""
                                }) {
                                    HStack {
                                        Text(prompt.title)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .background(.white)
                                }
                                .font(.manrope(size: 14, weight: .medium))
                                .padding(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .tint(.gray)
                                if prompt != filterdPrompts.last {
                                    Divider().foregroundColor(.gray)
                                }
                            }
                            Spacer().frame(height: 4)
                        }
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(key: SizeKey.self, value: proxy.size)
                            }.onPreferenceChange(SizeKey.self) {
                                commnadCardHeight = $0.height
                            }
                        }

                    }
                    .frame(maxHeight: min(commnadCardHeight, 180))
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 12)
                    .padding(.horizontal, 20)
                }
                if let selectedPrompt {
                    HStack {
                        Spacer(minLength: 0)
                        HStack(spacing: 4) {
                            Text(selectedPrompt.title)
                                .lineLimit(1)
                                .font(.manrope(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.7))
                            Button(action: {
                                self.selectedPrompt = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                            }.tint(.black.opacity(0.8))
                        }
                        .padding(.init(top: 4, leading: 10, bottom: 4, trailing: 10))
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 12)
                    }.padding(.horizontal, 20)
                }

                HStack {
                    TextField(text: $inputText) {
                        Text("Say something" + (conversation == mainConversation ? " or enter '/'" : ""))
                    }
                    .focused($isFocused)
                    .tint(Color.black.opacity(0.8))
                    .submitLabel(.send)
                    .onChange(of: inputText) { newValue in
                        if conversation == mainConversation {
                            if newValue.starts(with: "/") {
                                showCommands = true
                            } else {
                                showCommands = false
                            }
                        }
                    }
                    .onSubmit {
                        completeMessage()
                    }
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
                            if #available(iOS 16.0, *) {
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
                            } else {
                                Image(systemName: "paperplane.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 28, height: 28)
                                    .tint(
                                        .black.opacity(0.8)
                                    )
                            }
                        }
                        .disabled(inputText.isEmpty)
                    }

                }
                .frame(height: 50)
                .padding(.leading, 20)
                .padding(.trailing, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 8)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }.onAppear {
            queryMessages(cid: conversation.id)
        }.onChange(of: conversation) { newValue in
            selectedPrompt = nil
            inputText = ""
            queryMessages(cid: newValue.id)
        }.sheet(isPresented: $showAddConversation) {
            AddConversationView(conversation: conversation) { _ in
                showAddConversation = false
            }
        }.font(.manrope(size: 16, weight: .medium))
    }

    struct SizeKey: PreferenceKey {
        static var defaultValue = CGSize.zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
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
        let newMessage = Message(role: "user", content: sendText)
        Task {
            let chatMessage = ChatMessage(role: "user", content: sendText, conversationId: conversation.id)
            await db?.upsert(model: chatMessage)
            queryMessages(cid: conversation.id)
            if let selectedPrompt {
                await completeMessages([newMessage], prompt: selectedPrompt.prompt)
            } else {
                let messagesToSend = messages.suffix(contextCount).map({ Message(role: $0.role, content: $0.content) }) + [newMessage]
                await completeMessages(messagesToSend)
            }
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
        let messagesToSend = messages.suffix(contextCount + 1).map({ Message(role: $0.role, content: $0.content) })
        Task {
            if let selectedPrompt {
                await completeMessages(messagesToSend.suffix(1), prompt: selectedPrompt.prompt)
            }
            await completeMessages(messagesToSend)
        }
    }

    func completeMessages(_ messages: [Message], prompt: String? = nil) async {
        let result = await CatApi.complete(messages: messages, with: prompt ?? conversation.prompt)
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
