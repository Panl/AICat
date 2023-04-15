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
    @EnvironmentObject var appStateVM: AICatStateViewModel
    @State var inputText: String = ""
    @State var isSending = false
    @State var error: NSError?
    @State var showAddConversation = false
    @State var showClearMesssageAlert = false
    @State var showParamEditSheetView = false
    @State var isAIGenerating = false
    @State var showCommands = false
    @State var commnadCardHeight: CGFloat = 0
    @FocusState var isFocused: Bool

    let conversation: Conversation

    var filterdPrompts: [Conversation] {
        let query = inputText.lowercased().trimmingCharacters(in: .whitespaces)
        return appStateVM.conversations.filter { !$0.prompt.isEmpty }.filter { $0.title.lowercased().contains(query) || $0.prompt.lowercased().contains(query) || query.isEmpty }
    }

    @State var selectedPrompt: Conversation?

    var promptText: String {
        selectedPrompt?.prompt ?? conversation.prompt
    }

    var contextMessages: Int {
        conversation.contextMessages
    }

    let onChatsClick: () -> Void

    init(conversation: Conversation, onChatsClick: @escaping () -> Void) {
        self.conversation = conversation
        self.onChatsClick = onChatsClick
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
                            .tint(.primary)
                            .frame(width: 24, height: 24)
                    }.buttonStyle(.borderless)
                    Spacer()
                    VStack(spacing: 0) {
                        Text(conversation.title)
                            .font(.manrope(size: 16, weight: .heavy))
                            .lineLimit(1)
                        if !promptText.isEmpty {
                            Text(promptText)
                                .font(.manrope(size: 12, weight: .regular))
                                .opacity(0.4)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Menu {
                        if !conversation.isMain {
                            Button(action: editConversation) {
                                Label("Edit Prompt", systemImage: "note.text")
                            }
                        }
                        Button(action: { showParamEditSheetView = true }) {
                            Label("Edit Model", systemImage: "rectangle.and.pencil.and.ellipsis")
                        }
                        Button(role: .destructive, action: { showClearMesssageAlert = true }) {
                            Label("Clean Messages", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 24, height: 24)
                            .clipShape(Rectangle())
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                    .alert("Are you sure to clean all messages?", isPresented: $showClearMesssageAlert) {
                        Button("Sure", role: .destructive) {
                            cleanMessages()
                        }
                        Button("Cancel", role: .cancel) {
                            showClearMesssageAlert = false
                        }
                    }
                    .tint(.primary)
                }
                .padding(.horizontal, 20)
                .frame(height: 44)
                Spacer(minLength: 0)
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            Spacer().frame(height: 4)
                                .id("Top")
                            ForEach(appStateVM.messages, id: \.id) { message in
                                MessageView(message: message)
                                    .id(message.id)
                                    .contextMenu {
                                        Button(action: {
                                            SystemUtil.copyToPasteboard(content: message.content)
                                        }) {
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
                                } clear: {
                                    self.error = nil
                                }
                            }
                            if isAIGenerating && isSending {
                                InputingMessageView().id("generating")
                            }
                            Spacer().frame(height: 80)
                                .id("Bottom")
                        }
                    }
                    .gesture(DragGesture().onChanged { _ in
                        self.endEditing(force: true)
                    })
                    .onChange(of: appStateVM.messages) { _ in
                        withAnimation {
                            proxy.scrollTo("Bottom")
                        }
                    }
                    .onChange(of: isAIGenerating) { _ in
                        withAnimation {
                            proxy.scrollTo("Bottom")
                        }
                    }
                    .onChange(of: isFocused) { _ in
                        Task {
                            try await Task.sleep(nanoseconds: 300_000_000)
                            withAnimation {
                                proxy.scrollTo("Bottom")
                            }
                        }
                    }
                }.padding(.bottom, 36)
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
                                    .background(Color.background)
                                }
                                .buttonStyle(.borderless)
                                .font(.manrope(size: 14, weight: .medium))
                                .padding(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .tint(.blackText.opacity(0.5))
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
                    .background(Color.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .primary.opacity(0.1), radius: 12)
                    .padding(.horizontal, 20)
                }
                if let selectedPrompt {
                    HStack {
                        Spacer(minLength: 0)
                        HStack(spacing: 4) {
                            Text(selectedPrompt.title)
                                .lineLimit(1)
                                .font(.manrope(size: 14, weight: .semibold))
                                .foregroundColor(.blackText.opacity(0.7))
                            Button(action: {
                                self.selectedPrompt = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.borderless)
                            .tint(.blackText.opacity(0.8))
                        }
                        .padding(.init(top: 4, leading: 10, bottom: 4, trailing: 6))
                        .background(Color.background)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .primary.opacity(0.1), radius: 12)
                    }.padding(.horizontal, 20)
                }

                HStack(alignment: .bottom, spacing: 4) {
                    TextEditView(text: $inputText) {
                        Text("Say something" + (conversation.isMain ? " or enter 'space'" : ""))
                    }
                    .textFieldStyle(.plain)
                    .frame(minHeight: 26)
                    .focused($isFocused)
                    .tint(.blackText.opacity(0.8))
                    .onChange(of: inputText) { newValue in
                        if conversation.isMain {
                            if newValue.starts(with: " ") {
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
                        Button(action: {
                            CatApi.cancelMessageStream()
                        }) {
                            Rectangle()
                                .foregroundColor(.primary)
                                .frame(width: 17, height: 17)
                                .cornerRadius(2)
                                .opacity(0.5)
                        }
                        .frame(width: 26, height: 26)
                        .buttonStyle(.borderless)
                    }
                    Button(
                        action: {
                            completeMessage()
                        }
                    ) {
                        if isSending {
                            LoadingIndocator()
                                .frame(width: 20, height: 20)
                        } else {
                            if #available(iOS 16.0, *) {
                                Image(systemName: "paperplane.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 26, height: 26)
                                    .tint(
                                        LinearGradient(
                                            colors: [.primary.opacity(0.9), .primary.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing)
                                    )
                            } else {
                                Image(systemName: "paperplane.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 26, height: 26)
                                    .tint(
                                        .primary.opacity(0.8)
                                    )
                            }
                        }
                    }
                    .keyboardShortcut(KeyEquivalent.return, modifiers: [.command])
                    .frame(width: 26, height: 26)
                    .buttonStyle(.borderless)
                    .disabled(inputText.isEmpty)
                }
                .padding(.vertical, 12)
                .frame(minHeight: 50)
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .background(Color.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .primary.opacity(0.1), radius: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }.task {
            await appStateVM.queryMessages(cid: conversation.id)
        }.onChange(of: conversation.id) { newValue in
            selectedPrompt = nil
            inputText = ""
            error = nil
            appStateVM.resetMessages()
            showCommands = false
            Task {
                await appStateVM.queryMessages(cid: newValue)
            }
        }.sheet(isPresented: $showAddConversation) {
            AddConversationView(conversation: conversation) {
                showAddConversation = false
            }
        }.sheet(isPresented: $showParamEditSheetView) {
            if #available(iOS 16, *) {
                ParamsEditView(conversation: conversation)
                    .presentationDetents([.height(480)])
                    .presentationDragIndicator(.visible)
            } else {
                ParamsEditView(conversation: conversation)
            }
        }
        .font(.manrope(size: 16, weight: .regular))
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
            for var message in appStateVM.messages {
                message.timeRemoved = timeRemoved
                await appStateVM.saveMessage(message)
            }
            await appStateVM.queryMessages(cid: conversation.id)
        }
    }

    func deleteMessage(_ message: ChatMessage) {
        Task {
            var messageToRemove = message
            messageToRemove.timeRemoved = Date.now.timeInSecond
            await appStateVM.saveMessage(messageToRemove)
            await appStateVM.queryMessages(cid: conversation.id)
        }
    }

    func completeMessage() {
        if appStateVM.needBuyPremium() {
            return
        }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        let sendText = text
        inputText = ""
        let newMessage = Message(role: "user", content: sendText)
        Task {
            let chatMessage = ChatMessage(role: "user", content: sendText, conversationId: conversation.id, model: conversation.model)
            await appStateVM.saveMessage(chatMessage)
            await appStateVM.queryMessages(cid: conversation.id)
            isAIGenerating = true
            if let selectedPrompt {
                await completeMessages([newMessage], selected: selectedPrompt, replyToId: chatMessage.id)
            } else {
                let messagesToSend = appStateVM.messages.suffix(contextMessages).map({ Message(role: $0.role, content: $0.content) }) + [newMessage]
                await completeMessages(messagesToSend, replyToId: chatMessage.id)
            }
        }
    }

    func retryComplete() {
        error = nil
        isSending = true
        let messagesToSend = appStateVM.messages.suffix(contextMessages + 1).map({ Message(role: $0.role, content: $0.content) })
        let replyToId = appStateVM.messages.last?.id ?? ""
        Task {
            isAIGenerating = true
            if let selectedPrompt {
                await completeMessages(messagesToSend.suffix(1), selected: selectedPrompt, replyToId: replyToId)
            } else {
                await completeMessages(messagesToSend, replyToId: replyToId)
            }
        }
    }

    func completeMessages(_ messages: [Message], selected: Conversation? = nil, replyToId: String) async {
        var chatMessage = ChatMessage(role: "assistant", content: "", conversationId: conversation.id)
        chatMessage.replyToId = replyToId
        do {
            let stream = try await CatApi.completeMessageStream(messages: messages, conversation: selected ?? conversation)
            for try await (model, delta) in stream {
                if let role = delta.role {
                    chatMessage.role = role
                }
                if let content = delta.content {
                    chatMessage.content += content
                }
                chatMessage.model = model
                await appStateVM.saveMessage(chatMessage)
                isAIGenerating = false
                appStateVM.incrementSentMessageCount()
            }
            isSending = false
        } catch {
            let err = error as NSError
            if err.code != -999 {
                self.error = err
                deleteMessage(chatMessage)
            }
            isAIGenerating = false
            isSending = false

        }
    }
}

struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationView(
            conversation: Conversation(title: "Mini Chat", prompt: "hello hello hello hello hello hello hello hello hello hello "),
            onChatsClick: { }
        )
    }
}
