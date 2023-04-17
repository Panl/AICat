//
//  AICatStateViewModel.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/31.
//

import SwiftUI
import Combine
import Blackbird
import ApphudSDK
#if canImport(UIKit)
import UIKit
#endif

fileprivate let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/db.sqlite"
fileprivate let mainConversation = Conversation(id: "AICat.Conversation.Main", title: "AICat Main", prompt: "")

@MainActor class AICatStateViewModel: NSObject, ObservableObject {
    var db = try! Blackbird.Database(path: dbPath, options: .debugPrintEveryQuery)
    @Published private(set) var conversations: [Conversation] = [mainConversation]
    @Published private(set) var currentConversation = mainConversation
    @Published private(set) var messages: [ChatMessage] = []
    @Published var showAddAPIKeySheet: Bool = false
    @Published var showPremumPage: Bool = false
    @Published var monthlyPremium: ApphudProduct?

    @Published private(set) var main = mainConversation
    @AppStorage("request.temperature") var temperature: Double = 1.0
    @AppStorage("request.context.messages") var messagesCount: Int = 0
    @AppStorage("request.model") var model: String = "gpt-3.5-turbo"
    @AppStorage("db.conversations.didMigrateParams") var didMigrateParams: Bool = false
    @AppStorage("AICat.developerMode") var developMode: Bool = false

    @Published var sentMessageCount: Int64 = 0
    @Published var shareMessagesSnapshot: UIImage?
    @Published var saveImageToast: Toast?

    var freeMessageCount: Int64 {
        #if DEBUG
        return 5
        #else
        return 20
        #endif
    }

    private var cancellable: AnyCancellable?

    override init() {
        super.init()
        NSUbiquitousKeyValueStore.default.synchronize()
        cancellable = NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] _ in
                self?.fetchValueFromICloud()
            }
        fetchValueFromICloud()
    }

    func fetchValueFromICloud() {
        let value = NSUbiquitousKeyValueStore.default.longLong(forKey: "AICat.sentMessageCount")
        sentMessageCount = value
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

    var allConversations: [Conversation] {
        [main] + conversations
    }

    var isPremium: Bool {
        UserDefaults.openApiKey != nil || hasPremiumAccess
    }

    var isDeveloperModeEnable: Bool {
        UserDefaults.openApiKey != nil || developMode
    }

    private var hasPremiumAccess: Bool {
        if let subscription = Apphud.subscription() {
            if subscription.isActive() {
                if !subscription.isSandbox {
                    return true
                }
                if subscription.isSandbox && SystemUtil.maybeFromTestFlight {
                    return true
                }
            }
            return false
        }
        return false
    }

    func writeMainToDBIfNeeded() async {
        if let dbMain = try! await Conversation.read(from: db, id: mainConversation.id) {
            main = dbMain
        } else {
            var mainChatToSave = mainConversation
            mainChatToSave.temperature = temperature
            mainChatToSave.contextMessages = messagesCount
            mainChatToSave.model = model
            await saveConversation(mainChatToSave)
        }
    }

    func migrateConversationParamsIfNeeded() async {
        if !didMigrateParams {
            let chats = try! await Conversation.read(from: db, matching: \.$timeRemoved == 0 && \.$id != mainConversation.id, orderBy: .descending(\.$timeCreated))
            let defaultChat = Conversation(title: "", prompt: "")
            for var chat in chats {
                chat.contextMessages = defaultChat.contextMessages
                chat.temperature = defaultChat.temperature
                chat.frequencyPenalty = defaultChat.frequencyPenalty
                chat.presencePenalty = defaultChat.presencePenalty
                chat.topP = defaultChat.topP
                chat.model = defaultChat.model
                await db.upsert(model: chat)
            }
            didMigrateParams = true
        }
    }

    func queryConversations() async {
        await writeMainToDBIfNeeded()
        await migrateConversationParamsIfNeeded()
        let chats = try! await Conversation.read(from: db, matching: \.$timeRemoved == 0 && \.$id != mainConversation.id, orderBy: .descending(\.$timeCreated))
        conversations = chats
    }

    func queryMessages(cid: String) async {
        let queryMessages = (try! await ChatMessage.read(from: db, matching: \.$conversationId == cid && \.$timeRemoved == 0, orderBy: .ascending(\.$timeCreated)))
        withAnimation {
            messages = queryMessages
        }
    }

    func queryMessage(mid: String) async -> ChatMessage? {
        try! await ChatMessage.read(from: db, id: mid)
    }

    func saveMessage(_ message: ChatMessage) async {
        await db.upsert(model: message)
        await queryMessages(cid: currentConversation.id)
    }

    func saveConversation(_ conversation: Conversation) async {
        await db.upsert(model: conversation)
        await queryConversations()
    }

    func setCurrentConversation(_ conversation: Conversation?) {
        self.currentConversation = conversation ?? main
    }

    func resetMessages() {
        messages = []
    }

    func fetchPayWall() async {
        if let payWall = await Apphud.paywalls().first, let product = payWall.products.first {
            monthlyPremium = product
        }
    }

    func needBuyPremium() -> Bool {
        if !isPremium && sentMessageCount >= freeMessageCount {
            showPremumPage = true
            return true
        }
        return false
    }

    func shareMessage(_ message: ChatMessage) {
        let replyToId = message.replyToId
        Task {
            var messages = [message]
            if let replyToMessage = await queryMessage(mid: replyToId) {
                messages = [replyToMessage, message]
            }
            await MainActor.run {
                let title = currentConversation.title
                var prompt = currentConversation.prompt
                if prompt.isEmpty {
                    prompt = "Your ultimate AI assistant"
                }
                let shareMessagesView = ShareMessagesView(title: title, prompt: prompt, messages: messages)
                let image = shareMessagesView.snapshot()
                shareMessagesSnapshot = image
            }
        }
    }

    func saveImageToAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
        shareMessagesSnapshot = nil
    }


    @objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            saveImageToast = Toast(type: .error, message: "Save image failed, \(error.localizedDescription)", duration: 4)
        } else {
            saveImageToast = Toast(type: .success, message: "Image saved!")
        }
    }
}
