//
//  ConversationView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird
import Foundation
import ApphudSDK
import Combine
import OpenAI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

class ConversationViewModel: ObservableObject {

    @Published
    var conversation: Conversation = mainConversation
    @Published
    var messages: [ChatMessage] = []
    @Published
    var inputText: String = ""
    @Published
    var isSending = false
    @Published
    var error: NSError?
    @Published
    var showAddConversation = false
    @Published
    var showClearMessageAlert = false
    @Published
    var showParamEditSheetView = false
    @Published
    var showCommands = false
    @Published
    var toast: Toast?
    @Published
    var tappedMessageId: String?
    @Published
    var showPremiumPage = false
    @Published
    var selectedPrompt: Conversation?
    @Published
    var prompts: [Conversation] = []
    @Published
    var shareSnapshot: ImageType?
    @Published
    var saveImageToast: Toast?
    @Published
    var sentMessageCount: Int64 =  NSUbiquitousKeyValueStore.default.longLong(forKey: "AICat.sentMessageCount")
    @Published
    var currentContextCount: Int = 0

    var promptText: String {
        selectedPrompt?.prompt ?? conversation.prompt
    }

    var filterdPrompts: [Conversation] {
        let query = inputText.lowercased().trimmingCharacters(in: .whitespaces)
        return prompts.filter { !$0.prompt.isEmpty }.filter { $0.title.lowercased().contains(query) || $0.prompt.lowercased().contains(query) || query.isEmpty }
    }

    var freeMessageCount: Int64 {
        return 5
    }

    var isPremium: Bool {
        UserDefaults.openApiKey != nil || UserDefaults.hasPremiumAccess
    }

    var needBuyPremium: Bool {
        if !isPremium && sentMessageCount >= freeMessageCount {
            return true
        }
        return false
    }

    var streamChatCancelable: AnyCancellable?

    var contextMessages: [ChatMessage] {
        let count = conversation.contextMessages + (isSending ? 1 : 0)
        if let index = messages.lastIndex(where: { $0.isNewSession }) {
            return Array(messages[index...].filter({ !$0.isNewSession }).suffix(count))
        }
        return messages.suffix(count)
    }

    func saveMessage(_ message: ChatMessage, needSync: Bool) {
        upsertMessage(message)
        Task {
            if needSync {
                await DataStore.saveAndSync(message)
            } else {
                await DataStore.save(message)
            }
        }
    }

    private func upsertMessage(_ message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
        messages.sort(by: { $0.timeCreated < $1.timeCreated })
        if message.isNewSession {
            currentContextCount = contextMessages.count
        }
    }

    func deleteMessage(_ message: ChatMessage) {
        withAnimation {
            messages.removeAll(where: { $0.id == message.id })
            currentContextCount = contextMessages.count
            Task {
                await removeMessage(message)
            }
            while let last = messages.last, last.isNewSession {
                if messages.count == 1 {
                    messages.removeLast()
                    Task {
                        await removeMessage(last)
                    }
                } else {
                    let count = messages.count
                    let beforeLast = messages[count - 2]
                    if beforeLast.isNewSession {
                        messages.removeLast()
                        Task {
                            await removeMessage(last)
                        }
                    } else {
                        break
                    }
                }
            }
        }
    }

    private func removeMessage(_ message: ChatMessage) async {
        var messageToRemove = message
        messageToRemove.timeRemoved = Date.now.timeInSecond
        await DataStore.saveAndSync(messageToRemove)
    }

    func cleanMessages(_ messages: [ChatMessage]) {
        Task {
            let messagesToDelete = messages.map { item in
                var message = item
                message.timeRemoved = Date.now.timeInSecond
                return message
            }
            await DataStore.saveAndSync(items: messagesToDelete)
            withAnimation {
                self.messages = []
                currentContextCount = contextMessages.count
            }
        }
    }

    func queryMessages() {
        messages = []
        let cid = conversation.id
        Task {
            let result = try! await ChatMessage.read(from: db, matching: \.$conversationId == cid && \.$timeRemoved == 0, orderBy: .ascending(\.$timeCreated))
            await MainActor.run {
                messages = result
                currentContextCount = contextMessages.count
            }
        }
    }

    func tapMessage(_ message: ChatMessage) {
        withAnimation {
            if tappedMessageId == message.id {
                tappedMessageId = nil
            } else {
                tappedMessageId = message.id
            }
        }
    }

    func hoverMessage(_ message: ChatMessage?) {
        withAnimation {
            tappedMessageId = message?.id
        }
    }

    func resetConversation() {
        selectedPrompt = nil
        inputText = ""
        error = nil
        showCommands = false
        queryMessages()
    }

    func sendMessage() {
        if needBuyPremium {
            showPremiumPage = true
            return
        }
        complete()
    }

    func complete() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let conversation = conversation
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        let sendText = text
        inputText = ""
        let chatMessage = ChatMessage(role: "user", content: sendText, conversationId: conversation.id, model: conversation.model)
        saveMessage(chatMessage, needSync: false)
        streamChatCombine(replyToId: chatMessage.id)
    }

    var currentResponse: ChatMessage?
    func cancelStream() {
        streamChatCancelable?.cancel()
        isSending = false
        if let currentResponse {
            if currentResponse.content.isEmpty {
                deleteMessage(currentResponse)
            } else {
                saveMessage(currentResponse, needSync: true)
            }
            self.currentResponse = nil
        }
        currentContextCount = contextMessages.count
    }

    func retry() {
        guard let message = messages.last else { return }
        error = nil
        isSending = true
        streamChatCombine(replyToId: message.id)
    }

    func streamChatCombine(replyToId: String) {
        let conversation = conversation
        let contextMsgs = contextMessages
        var responseMessage = ChatMessage(role: "assistant", content: "", conversationId: conversation.id)
        responseMessage.replyToId = replyToId
        responseMessage.timeCreated += 1
        self.currentResponse = responseMessage
        saveMessage(responseMessage, needSync: false)
        let chatStream: AnyPublisher<Result<ChatStreamResult, Error>, Error>
        if let selectedPrompt {
            let msgToSend = contextMsgs.suffix(1).map({Chat(role: .init(name: $0.role), content: $0.content)})
            chatStream = CatApi.streamChat(messages: msgToSend, conversation: selectedPrompt)
        } else {
            let msgsToSend = contextMsgs.map({ Chat(role: .init(name: $0.role), content: $0.content) })
            chatStream = CatApi.streamChat(messages: msgsToSend, conversation: conversation)
        }
        streamChatCancelable = chatStream
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.saveMessage(responseMessage, needSync: true)
                        self?.isSending = false
                        self?.incrementSentMessageCount()
                        self?.currentContextCount = self?.contextMessages.count ?? 0
                    case .failure(let error):
                        self?.handleChatStreamFailure(error: error, message: responseMessage)
                    }
                },
                receiveValue: { [weak self] result in
                    switch result {
                    case .success(let chatResult):
                        let delta = chatResult.choices.first?.delta
                        if let role = delta?.role?.rawValue {
                            responseMessage.role = role
                        }
                        if let content = delta?.content {
                            responseMessage.content += content
                        }
                        responseMessage.model = chatResult.model
                        responseMessage.timeCreated = Date.now.timeInSecond
                        self?.currentResponse = responseMessage
                        self?.upsertMessage(responseMessage)
                    case .failure(let error):
                        self?.handleChatStreamFailure(error: error, message: responseMessage)
                    }

                }
            )
    }

    private func handleChatStreamFailure(error: Error, message: ChatMessage) {
        let err = error as NSError
        isSending = false
        self.error = err
        deleteMessage(message)
    }

    func incrementSentMessageCount() {
        sentMessageCount += 1
        if sentMessageCount > freeMessageCount {
            sentMessageCount = freeMessageCount
        }
        let keyValueStore = NSUbiquitousKeyValueStore.default
        keyValueStore.set(sentMessageCount, forKey: "AICat.sentMessageCount")
        keyValueStore.synchronize()
    }


    func queryMessage(mid: String) async -> ChatMessage? {
        try! await ChatMessage.read(from: db, id: mid)
    }

    func generateMessageSnapshot(_ message: ChatMessage, imageWidth: CGFloat, conversation: Conversation) async -> ImageType {
        let replyToId = message.replyToId
        let replyToMessage = await queryMessage(mid: replyToId)
        let shareMessagesView = await MainActor.run {
            var messages = [message]
            if let replyToMessage {
                messages = [replyToMessage, message]
            }
            let title = conversation.title
            var prompt = conversation.prompt
            if prompt.isEmpty {
                prompt = "Your ultimate AI assistant"
            }
            let width = min(560, imageWidth)
            return ShareMessagesView(title: title, prompt: prompt, messages: messages).frame(width: width)
        }
        return await shareMessagesView.snapshot()
    }

    func shareMessage(_ message: ChatMessage, width: CGFloat) {
        Task {
            shareSnapshot = await generateMessageSnapshot(message, imageWidth: width, conversation: conversation)
        }
    }

    func saveToAlbum(image: ImageType) {
        do {
            try saveImageToAlbum(image: image)
            saveImageToast = Toast(type: .success, message: "Image saved!")
        } catch {
            saveImageToast = Toast(type: .error, message: "Save image falied!")
        }
    }

    func saveImageToAlbum(image: ImageType) throws {
#if os(iOS)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
#elseif os(macOS)
        if let url = showSavePanel()  {
            try savePNG(image: image, path: url)
        }
#endif
    }

    func exportToMD() {
#if os(macOS)
        if let folder = showSaveMDPanel() {
            _ = SystemUtil.exportToMarkDown(messages: messages, fileUrl: folder)
        }
#elseif os(iOS)
        if let url = SystemUtil.saveMessageAsMD(messages: messages, title: conversation.title) {
            DocumentPicker.shared.export(file: url)
        }
#endif
    }

#if os(macOS)
    func showSavePanel() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save your image"
        savePanel.message = "Choose a folder and a name to store the image."
        savePanel.nameFieldLabel = "Image file name:"

        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }

    func showSaveMDPanel() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.text]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Export your messages"
        savePanel.message = "Choose a folder and a name to store the Markdown file."
        savePanel.nameFieldLabel = "Messages file name:"
        savePanel.nameFieldStringValue = "Untitled.md"

        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }

    func savePNG(image: NSImage, path: URL) throws {
        let imageRepresentation = NSBitmapImageRep(data: image.tiffRepresentation!)
        let pngData = imageRepresentation?.representation(using: .png, properties: [:])
        try pngData!.write(to: path)
    }
#endif

}

struct ConversationView: View {
    @State var commnadCardHeight: CGFloat = 0
    @FocusState var isFocused: Bool
    @State var size: CGSize = .zero
    @State var subscription: AnyCancellable?
    @ObservedObject var viewStore: ConversationViewModel
    @EnvironmentObject var chatState: ChatStateViewModel

    let onChatsClick: () -> Void

    init(onChatsClick: @escaping () -> Void, store: ConversationViewModel) {
        self.onChatsClick = onChatsClick
        self.viewStore = store
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                toolbar(viewStore: viewStore)
                Spacer(minLength: 0)
                messageList(viewStore: viewStore)
            }
            VStack {
                if viewStore.showCommands, !viewStore.filterdPrompts.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 4)
                            ForEach(viewStore.filterdPrompts) { prompt in
                                Button(action: {
                                    viewStore.selectedPrompt = prompt
                                    viewStore.inputText = ""
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
                                if prompt != viewStore.filterdPrompts.last {
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
                    .shadow(color: .primaryColor.opacity(0.1), radius: 12)
                    .padding(.horizontal, 16)
                }
                if let selectedPrompt = viewStore.selectedPrompt {
                    HStack {
                        Spacer(minLength: 0)
                        HStack(spacing: 4) {
                            Text(selectedPrompt.title)
                                .lineLimit(1)
                                .font(.manrope(size: 14, weight: .semibold))
                                .foregroundColor(.blackText.opacity(0.7))
                            Button(action: {
                                viewStore.selectedPrompt = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.borderless)
                            .tint(.blackText.opacity(0.8))
                        }
                        .padding(.init(top: 4, leading: 10, bottom: 4, trailing: 6))
                        .background(Color.background)
                        .cornerRadius(16)
                        .shadow(color: .primaryColor.opacity(0.1), radius: 12)
                    }.padding(.horizontal, 20)
                } else if viewStore.conversation.contextMessages > 0 {
                    HStack {
                        Spacer(minLength: 0)
                        Button(action: {
                            if let last = viewStore.messages.last {
                                HapticEngine.trigger()
                                if last.isNewSession {
                                    viewStore.deleteMessage(last)
                                } else {
                                    viewStore.saveMessage(ChatMessage.newSession(cid: viewStore.conversation.id), needSync: false)
                                }
                            }
                        }, label: {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("\(viewStore.currentContextCount)/\(viewStore.conversation.contextMessages)")
                                    .lineLimit(1)
                                    .font(.manrope(size: 14, weight: .semibold))
                                    .foregroundColor(.blackText.opacity(0.7))
                            }
                            .padding(.init(top: 4, leading: 6, bottom: 4, trailing: 12))
                        })
                        .background(Color.background)
                        .cornerRadius(16)
                        .shadow(color: .primaryColor.opacity(0.1), radius: 12)
                        .disabled(viewStore.isSending)
                        .foregroundColor(.blackText.opacity(0.7))
                        .buttonStyle(.borderless)
                    }.padding(.horizontal, 20)
                }

                HStack(alignment: .bottom, spacing: 4) {
                    TextField(text: $viewStore.inputText, axis: .vertical) {
                        ZStack {
                            if viewStore.conversation.isMain {
                                Text("Say something or enter 'space'")
                            } else {
                                Text("Say something")
                            }
                        }
                    }
                    .lineLimit(...8)
                    .textFieldStyle(.plain)
                    .frame(minHeight: 26)
                    .focused($isFocused)
                    .tint(.blackText.opacity(0.8))
                    .onChange(of: viewStore.inputText) { newValue in
                        if viewStore.conversation.isMain {
                            if newValue.starts(with: " ") {
                                viewStore.showCommands = true
                            } else {
                                viewStore.showCommands = false
                            }
                        }
                    }
                    .onSubmit {
                        viewStore.sendMessage()
                    }
                    .onTapGesture {}

                    if viewStore.isSending {
                        Button(action: {
                            HapticEngine.trigger()
                            viewStore.cancelStream()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 26, height: 26)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primaryColor.opacity(0.9), .primaryColor.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing)
                                )
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Button(
                            action: {
                                viewStore.sendMessage()
                                HapticEngine.trigger()
                            }
                        ) {
                            Image(systemName: "paperplane.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 26, height: 26)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primaryColor.opacity(0.9), .primaryColor.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing)
                                )
                                .opacity(viewStore.inputText.isEmpty ? 0.4 : 1)
                        }
                        .keyboardShortcut(KeyEquivalent.return, modifiers: [.command])
                        .buttonStyle(.borderless)
                        .disabled(viewStore.inputText.isEmpty)
                    }
                }
                .padding(.vertical, 12)
                .frame(minHeight: 50)
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .background(Color.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .primaryColor.opacity(0.1), radius: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            viewStore.queryMessages()
            subscription = DataStore.receiveDataFromiCloud
                .receive(on: DispatchQueue.main)
                .sink {
                    viewStore.queryMessages()
                }
        }
        .onChange(of: viewStore.conversation.id) { newValue in
            viewStore.resetConversation()
        }.sheet(isPresented: $viewStore.showAddConversation) {
            AddConversationView(
                conversation: viewStore.conversation,
                onClose: {
                    viewStore.showAddConversation = false
                },
                onSave: { chat in
                    chatState.updateChat(chat)
                    viewStore.showAddConversation = false
                }
            )
        }.sheet(isPresented: $viewStore.showParamEditSheetView) {
            ParamsEditView(
                conversation: viewStore.conversation,
                showing: $viewStore.showParamEditSheetView,
                onUpdate: { chat in
                    chatState.updateChat(chat)
                }
            )
            .frame(minWidth: 350)
            .presentationDetents([.height(480)])
            .presentationDragIndicator(.visible)
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        size = proxy.size
                    }
            }
        }
        .sheet(isPresented: $viewStore.showPremiumPage) {
            PremiumPage(onClose: {
                viewStore.showPremiumPage = false
            })
        }
        .font(.manrope(size: 16, weight: .regular))
        .toast($viewStore.toast)
        .onTapGesture {
            endEditing(force: true)
        }
        .overlay {
            ShareMessagesImageOverlay(
                shareMessageSnapshot: viewStore.shareSnapshot,
                onClose: {
                    viewStore.shareSnapshot = nil
                },
                onSave: { image in
                    viewStore.saveToAlbum(image: image)
                }
            )
        }
        .toast($viewStore.saveImageToast)
    }

    func toolbar(viewStore: ConversationViewModel) -> some View {
        HStack(spacing: 18) {
            Button(action: {
                isFocused = false
                onChatsClick()
            }) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .tint(.primaryColor)
                    .frame(width: 24, height: 24)
            }.buttonStyle(.borderless)
            Spacer()
            VStack(spacing: 0) {
                Text(viewStore.conversation.title)
                    .font(.manrope(size: 16, weight: .heavy))
                    .lineLimit(1)
                if !viewStore.promptText.isEmpty {
                    Text(viewStore.promptText)
                        .font(.manrope(size: 12, weight: .regular))
                        .opacity(0.4)
                        .lineLimit(1)
                }
            }
            Spacer()
            Menu(content: {
                if !viewStore.conversation.isMain {
                    Button(action: {
                        viewStore.showAddConversation = true
                    }) {
                        Label("Edit Prompt", systemImage: "note.text")
                    }
                }
                Button(action: {
                    viewStore.showParamEditSheetView = true
                }) {
                    Label("Edit Model", systemImage: "rectangle.and.pencil.and.ellipsis")
                }
                Button(action: {
                    viewStore.exportToMD()
                }) {
                    Label("Export to Markdown", systemImage: "m.square")
                }
                Button(role: .destructive, action: {
                    viewStore.showClearMessageAlert = true
                }) {
                    Label("Clean Messages", systemImage: "trash")
                }
            }, label: {
                Image(systemName: "ellipsis")
                    .frame(width: 24, height: 24)
                    .clipShape(Rectangle())
            })
            .menuStyle(.borderlessButton)
            .frame(width: 24)
            .alert("Are you sure to clean all messages?", isPresented: $viewStore.showClearMessageAlert) {
                Button("Sure", role: .destructive) {
                    viewStore.cleanMessages(viewStore.messages)
                }
                Button("Cancel", role: .cancel) {
                    viewStore.showClearMessageAlert = false
                }
            }
            .tint(.primaryColor)
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
    }

    func messageList(viewStore: ConversationViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewStore.messages, id: \.id) { message in
                        MessageView(
                            message: message,
                            onDelete: {
                                HapticEngine.trigger()
                                viewStore.deleteMessage(message)
                            },
                            onCopy: {
                                SystemUtil.copyToPasteboard(content: message.content)
                                viewStore.toast = Toast(type: .info, message: "Message content copied", duration: 1.5)
                            },
                            onShare: {
                                HapticEngine.trigger()
                                endEditing(force: true)
                                viewStore.shareMessage(message, width: size.width)
                            },
                            showActions: message.id == viewStore.tappedMessageId
                        ).onTapGesture {
                            HapticEngine.trigger()
                            viewStore.tapMessage(message)
                        }
                        .onHover { isHover in
                            viewStore.hoverMessage(isHover ? message : nil)
                        }
                        .id(message.id)
                    }
                    if let error = viewStore.error {
                        ErrorMessageView(errorMessage: error.localizedDescription) {
                            viewStore.retry()
                        } clear: {
                            viewStore.error = nil
                        }
                    }
                    Spacer().frame(height: 80)
                        .id("Bottom")
                }
            }
            .simultaneousGesture(DragGesture().onChanged { _ in
                self.endEditing(force: true)
            })
            .onChange(of: viewStore.messages) { [old = viewStore.messages] newMessages in
                if old.last != newMessages.last {
                    if old.first?.conversationId != newMessages.first?.conversationId  {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            proxy.scrollTo("Bottom", anchor: .bottom)
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            withAnimation {
                                proxy.scrollTo("Bottom", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .onChange(of: isFocused) { value in
                if value {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        withAnimation {
                            proxy.scrollTo("Bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }.padding(.bottom, 36)
    }

    struct SizeKey: PreferenceKey {
        static var defaultValue = CGSize.zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
    }
}

struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationView(
            onChatsClick: { },
            store: ConversationViewModel()
        )
    }
}
