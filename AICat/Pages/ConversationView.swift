//
//  ConversationView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Alamofire
import ComposableArchitecture
import Blackbird
import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct ConversationFeature: ReducerProtocol {
    struct State: Equatable {
        var conversation: Conversation = mainConversation
        var messages: [ChatMessage] = []
        var inputText: String = ""
        var isSending = false
        var error: NSError?
        var showAddConversation = false
        var showClearMessageAlert = false
        var showParamEditSheetView = false
        var isAIGenerating = false
        var showCommands = false
        var toast: Toast?
        var tappedMessageId: String?
        var showPremiumPage = false
        var selectedPrompt: Conversation?
        var prompts: [Conversation] = []
        var shareSnapshot: ImageType?
        var saveImageToast: Toast?

        var promptText: String {
            selectedPrompt?.prompt ?? conversation.prompt
        }

        var filterdPrompts: [Conversation] {
            let query = inputText.lowercased().trimmingCharacters(in: .whitespaces)
            return prompts.filter { !$0.prompt.isEmpty }.filter { $0.title.lowercased().contains(query) || $0.prompt.lowercased().contains(query) || query.isEmpty }
        }
    }

    enum Action {
        case queryMessages(cid: String)
        case updateMessages([ChatMessage])
        case saveMessage(ChatMessage)
        case deleteMessage(ChatMessage)
        case sendMessage
        case setSending(Bool)
        case textChanged(String)
        case clearInputText
        case selectPrompt(Conversation?)
        case setAIGenerating(Bool)
        case setCompleteError(NSError?)
        case tapMessage(ChatMessage)
        case toggleAddConversation(Bool)
        case toggleClearMessageAlert(Bool)
        case toggleParamEditSheetView(Bool)
        case toggleShowPremiumPage(Bool)
        case hoverMessage(ChatMessage?)
        case setToast(Toast?)
        case cleanMessages([ChatMessage])
        case toggleShowCommands(Bool)
        case updateShareSnapshot(ImageType?)
        case shareMessage((ChatMessage, CGFloat))
        case saveToAlbum(ImageType)
        case setSaveImageToast(Toast?)
        case updateConversation(Conversation)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .queryMessages(let cid):
            state.messages.removeAll()
            return .task {
                let messages = await queryMessages(cid: cid)
                return .updateMessages(messages)
            }
        case .updateMessages(let messages):
            state.messages = messages
            return .none
        case .saveMessage(let message):
            if let index = state.messages.firstIndex(where: { $0.id == message.id }) {
                state.messages[index] = message
            } else {
                state.messages.append(message)
            }
            return .none
        case .deleteMessage(let message):
            state.messages.removeAll(where: { $0.id == message.id })
            Task {
                await deleteMessage(message)
            }
            return .none
        case .sendMessage:
            //TODO: check premium state
            return .run { [state] send in
                await complete(state: state, send: send)
            }
        case .textChanged(let text):
            state.inputText = text
            return .none
        case .setSending(let isSending):
            state.isSending = isSending
            return .none
        case .clearInputText:
            state.inputText = ""
            return .none
        case .selectPrompt(let prompt):
            state.selectedPrompt = prompt
            return .none
        case .setAIGenerating(let isGenerating):
            state.isAIGenerating = isGenerating
            return .none
        case .setCompleteError(let error):
            state.error = error
            return .none
        case .tapMessage(let message):
            if state.tappedMessageId == message.id {
                state.tappedMessageId = nil
            } else {
                state.tappedMessageId = message.id
            }
            return .none
        case .toggleAddConversation(let show):
            state.showAddConversation = show
            return .none
        case .toggleClearMessageAlert(let show):
            state.showClearMessageAlert = show
            return .none
        case .toggleParamEditSheetView(let show):
            state.showParamEditSheetView = show
            return .none
        case .toggleShowPremiumPage(let show):
            state.showPremiumPage = show
            return .none
        case .hoverMessage(let message):
            state.tappedMessageId = message?.id
            return .none
        case .setToast(let toast):
            state.toast = toast
            return .none
        case .cleanMessages(let messages):
            return .task {
                await cleanMessages(messages)
                return .updateMessages([])
            }
        case .toggleShowCommands(let show):
            state.showCommands = show
            return .none
        case .updateShareSnapshot(let snapshot):
            state.shareSnapshot = snapshot
            return .none
        case .shareMessage(let (message, width)):
            return .task { [chat = state.conversation] in
                let snapsot = await generateMessageSnapshot(message, imageWidth: width, conversation: chat)
                return .updateShareSnapshot(snapsot)
            }
        case .saveToAlbum(let image):
            do {
                try saveImageToAlbum(image: image)
                state.saveImageToast = Toast(type: .success, message: "Image saved!")
            } catch {
                state.saveImageToast = Toast(type: .error, message: "Image saved falied!")
            }
            return .none
        case .setSaveImageToast(let toast):
            state.saveImageToast = toast
            return .none
        case .updateConversation:
            return .none
        }

    }

    func saveMessage(_ message: ChatMessage) async {
        await db.upsert(model: message)
    }

    func deleteMessage(_ message: ChatMessage) async {
        var messageToRemove = message
        messageToRemove.timeRemoved = Date.now.timeInSecond
        await db.upsert(model: messageToRemove)
    }

    func cleanMessages(_ messages: [ChatMessage]) async {
        for var message in messages {
            message.timeRemoved = Date.now.timeInSecond
            await db.upsert(model: message)
        }
    }

    func queryMessages(cid: String) async -> [ChatMessage] {
        try! await ChatMessage.read(from: db, matching: \.$conversationId == cid && \.$timeRemoved == 0, orderBy: .ascending(\.$timeCreated))
    }

    func complete(state: State, send: Send<Action>) async {
        let text = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let conversation = state.conversation
        guard !text.isEmpty, !state.isSending else { return }
        await send(.setSending(true))
        let sendText = text
        await send(.clearInputText)
        let newMessage = Message(role: "user", content: sendText)
        let chatMessage = ChatMessage(role: "user", content: sendText, conversationId: conversation.id, model: conversation.model)
        await saveMessage(chatMessage)
        await send(.saveMessage(chatMessage))
        await send(.setAIGenerating(true))
        do {
            var responseMessage = ChatMessage(role: "assistant", content: "", conversationId: conversation.id)
            responseMessage.replyToId = chatMessage.id
            let stream: AsyncThrowingStream<(String, StreamResponse.Delta), Error>
            if let selectedPrompt = state.selectedPrompt {
                stream = try await CatApi.completeMessageStream(messages: [newMessage], conversation: selectedPrompt)
            } else {
                let messagesToSend = state.messages.suffix(conversation.contextMessages).map({ Message(role: $0.role, content: $0.content) }) + [newMessage]
                stream = try await CatApi.completeMessageStream(messages: messagesToSend, conversation: conversation)
            }
            for try await (model, delta) in stream {
                if let role = delta.role {
                    responseMessage.role = role
                }
                if let content = delta.content {
                    responseMessage.content += content
                }
                responseMessage.model = model
                await saveMessage(responseMessage)
                await send(.saveMessage(responseMessage))
                await send(.setAIGenerating(false))
            }
            await send(.setSending(false))
            // TODO: incrementSentMessageCount
        } catch {
            let err = error as NSError
            if err.code != -999 {
                await send(.setCompleteError(err))
                await deleteMessage(chatMessage)
            }
            await send(.setAIGenerating(false))
            await send(.setSending(false))
        }
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

    func saveImageToAlbum(image: ImageType) throws {
        #if os(iOS)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        #elseif os(macOS)
        if let url = showSavePanel()  {
            try savePNG(image: image, path: url)
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

    let store: StoreOf<ConversationFeature>
    let onChatsClick: () -> Void

    init(store: StoreOf<ConversationFeature>, onChatsClick: @escaping () -> Void) {
        self.onChatsClick = onChatsClick
        self.store = store
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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
                                        viewStore.send(.selectPrompt(prompt))
                                        viewStore.send(.clearInputText)
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
                                    viewStore.send(.selectPrompt(nil))
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.borderless)
                                .tint(.blackText.opacity(0.8))
                            }
                            .padding(.init(top: 4, leading: 10, bottom: 4, trailing: 6))
                            .background(Color.background)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .primaryColor.opacity(0.1), radius: 12)
                        }.padding(.horizontal, 20)
                    }

                    HStack(alignment: .bottom, spacing: 4) {
                        TextEditView(text: viewStore.binding(get: \.inputText, send: ConversationFeature.Action.textChanged)) {
                            ZStack {
                                if viewStore.conversation.isMain {
                                    Text("Say something or enter 'space'")
                                } else {
                                    Text("Say something")
                                }
                            }
                        }
                        .textFieldStyle(.plain)
                        .frame(minHeight: 26)
                        .focused($isFocused)
                        .tint(.blackText.opacity(0.8))
                        .onChange(of: viewStore.inputText) { newValue in
                            if viewStore.conversation.isMain {
                                if newValue.starts(with: " ") {
                                    viewStore.send(.toggleShowCommands(true))
                                } else {
                                    viewStore.send(.toggleShowCommands(false))
                                }
                            }
                        }
                        .onSubmit {
                            viewStore.send(.sendMessage)
                        }
                        .onTapGesture {}
                        if viewStore.isSending {
                            Button(action: {
                                HapticEngine.trigger()
                                //TODO: move to reducer
                                CatApi.cancelMessageStream()
                            }) {
                                Rectangle()
                                    .foregroundColor(.primaryColor)
                                    .frame(width: 17, height: 17)
                                    .cornerRadius(2)
                                    .opacity(0.5)
                            }
                            .frame(width: 26, height: 26)
                            .buttonStyle(.borderless)
                        }
                        Button(
                            action: {
                                viewStore.send(.sendMessage)
                                HapticEngine.trigger()
                            }
                        ) {
                            if viewStore.isSending {
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
                                                colors: [.primaryColor.opacity(0.9), .primaryColor.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing)
                                        )
                                } else {
                                    Image(systemName: "paperplane.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 26, height: 26)
                                        .tint(
                                            .primaryColor.opacity(0.8)
                                        )
                                }
                            }
                        }
                        .keyboardShortcut(KeyEquivalent.return, modifiers: [.command])
                        .frame(width: 26, height: 26)
                        .buttonStyle(.borderless)
                        .disabled(viewStore.inputText.isEmpty)
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
                viewStore.send(.queryMessages(cid: viewStore.conversation.id))
            }
            .onChange(of: viewStore.conversation.id) { newValue in
                viewStore.send(.selectPrompt(nil))
                viewStore.send(.clearInputText)
                viewStore.send(.setCompleteError(nil))
                viewStore.send(.toggleShowCommands(false))
                viewStore.send(.queryMessages(cid: viewStore.conversation.id))
            }.sheet(isPresented: viewStore.binding(get: \.showAddConversation, send: ConversationFeature.Action.toggleAddConversation)) {
                AddConversationView(
                    conversation: viewStore.conversation,
                    onClose: {
                        viewStore.send(.toggleAddConversation(true))
                    },
                    onSave: { chat in
                        viewStore.send(.updateConversation(chat))
                    }
                )
            }.sheet(isPresented: viewStore.binding(get: \.showParamEditSheetView, send: ConversationFeature.Action.toggleParamEditSheetView)) {
                if #available(iOS 16, *) {
                    ParamsEditView(
                        conversation: viewStore.conversation,
                        showing: viewStore.binding(get: \.showParamEditSheetView, send: ConversationFeature.Action.toggleParamEditSheetView),
                        onUpdate: { chat in
                            viewStore.send(.updateConversation(chat))
                        }
                    )
                    .presentationDetents([.height(480)])
                    .presentationDragIndicator(.visible)
                } else {
                    ParamsEditView(
                        conversation: viewStore.conversation,
                        showing: viewStore.binding(get: \.showParamEditSheetView, send: ConversationFeature.Action.toggleParamEditSheetView),
                        onUpdate: { chat in
                            viewStore.send(.updateConversation(chat))
                        }
                    )
                }
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            size = proxy.size
                        }
                }
            }
            .sheet(isPresented: viewStore.binding(get: \.showPremiumPage, send: ConversationFeature.Action.toggleShowPremiumPage)) {
                PremiumPage(showPremium: viewStore.binding(get: \.showPremiumPage, send: ConversationFeature.Action.toggleShowPremiumPage))
            }
            .font(.manrope(size: 16, weight: .regular))
            .toast(viewStore.binding(get: \.toast, send: ConversationFeature.Action.setToast))
            .onTapGesture {
                endEditing(force: true)
            }
            .overlay {
                ShareMessagesImageOverlay(
                    shareMessageSnapshot: viewStore.shareSnapshot,
                    onClose: {
                        viewStore.send(.updateShareSnapshot(nil))
                    },
                    onSave: { image in
                        viewStore.send(.saveToAlbum(image))
                    }
                )
            }
            .toast(viewStore.binding(get: \.saveImageToast, send: ConversationFeature.Action.setSaveImageToast))
        }
    }

    func toolbar(viewStore: ViewStoreOf<ConversationFeature>) -> some View {
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
                        viewStore.send(.toggleAddConversation(true))
                    }) {
                        Label("Edit Prompt", systemImage: "note.text")
                    }
                }
                Button(action: {
                    viewStore.send(.toggleParamEditSheetView(true))
                }) {
                    Label("Edit Model", systemImage: "rectangle.and.pencil.and.ellipsis")
                }
                Button(role: .destructive, action: {
                    viewStore.send(.toggleClearMessageAlert(true))
                }) {
                    Label("Clean Messages", systemImage: "trash")
                }
            }, label: {
                Image(systemName: "ellipsis")
                    .frame(width: 24, height: 24)
                    .clipShape(Rectangle())
            })
            .frame(width: 24)
            .alert("Are you sure to clean all messages?", isPresented: viewStore.binding(get: \.showClearMessageAlert, send: ConversationFeature.Action.toggleClearMessageAlert)) {
                Button("Sure", role: .destructive) {
                    viewStore.send(.cleanMessages(viewStore.messages))
                }
                Button("Cancel", role: .cancel) {
                    viewStore.send(.toggleClearMessageAlert(false))
                }
            }
            .tint(.primaryColor)
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
    }

    func messageList(viewStore: ViewStoreOf<ConversationFeature>) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Spacer().frame(height: 4)
                        .id("Top")
                    ForEach(viewStore.messages, id: \.id) { message in
                        MessageView(
                            message: message,
                            onDelete: {
                                HapticEngine.trigger()
                                viewStore.send(.deleteMessage(message))
                            },
                            onCopy: {
                                SystemUtil.copyToPasteboard(content: message.content)
                                let toast = Toast(type: .info, message: "Message content copied", duration: 1.5)
                                viewStore.send(.setToast(toast))
                            },
                            onShare: {
                                HapticEngine.trigger()
                                endEditing(force: true)
                                viewStore.send(.shareMessage((message, size.width)))
                            },
                            showActions: message.id == viewStore.tappedMessageId
                        ).onTapGesture {
                            HapticEngine.trigger()
                            viewStore.send(.tapMessage(message), animation: .default)
                        }
                        .onHover { isHover in
                            viewStore.send(.hoverMessage(isHover ? message : nil), animation: .default)
                        }
                        .id(message.id)
                    }
                    if let error = viewStore.error {
                        ErrorMessageView(errorMessage: error.localizedDescription) {
                            // TODO: retryComplete()
                        } clear: {
                            viewStore.send(.setCompleteError(nil))
                        }
                    }
                    if viewStore.isAIGenerating && viewStore.isSending {
                        InputingMessageView().id("generating")
                    }
                    Spacer().frame(height: 80)
                        .id("Bottom")
                }
            }
            .simultaneousGesture(DragGesture().onChanged { _ in
                self.endEditing(force: true)
            })
            .onChange(of: viewStore.messages) { [old = viewStore.messages] newMessages in
                if old.count <= newMessages.count {
                    if old.isEmpty {
                        proxy.scrollTo("Bottom")
                    } else {
                        withAnimation {
                            proxy.scrollTo("Bottom")
                        }
                    }
                }
            }
            .onChange(of: viewStore.isAIGenerating) { _ in
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

    struct SizeKey: PreferenceKey {
        static var defaultValue = CGSize.zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
    }
}

struct ConversationView_Previews: PreviewProvider {

    static let store = Store(initialState: ConversationFeature.State(), reducer: ConversationFeature())

    static var previews: some View {
        ConversationView(
            store: store,
            onChatsClick: { }
        )
    }
}
