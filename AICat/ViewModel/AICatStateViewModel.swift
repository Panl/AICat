//
//  AICatStateViewModel.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/31.
//

import SwiftUI
import Combine
import Blackbird

fileprivate let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/db.sqlite"
fileprivate let mainConversation = Conversation(id: "AICat.Conversation.Main", title: "AICat Main", prompt: "")

@MainActor class AICatStateViewModel: ObservableObject {
    var db = try! Blackbird.Database(path: dbPath, options: .debugPrintEveryQuery)
    @Published private(set) var conversations: [Conversation] = [mainConversation]
    @Published private(set) var currentConversation = mainConversation
    @Published private(set) var messages: [ChatMessage] = []
    @Published var showAddAPIKeySheet: Bool = false

    @Published private(set) var main = mainConversation
    @AppStorage("request.temperature") var temperature: Double = 1.0
    @AppStorage("request.context.messages") var messagesCount: Int = 0
    @AppStorage("request.model") var model: String = "gpt-3.5-turbo"

    var allConversations: [Conversation] {
        [main] + conversations
    }

    func writeMainToDBIfNeeded() async {
        if let dbMain = try! await Conversation.read(from: db, id: mainConversation.id) {
            main = dbMain
        } else {
            var mainChatToSave = mainConversation
            mainChatToSave.temperature = temperature
            mainChatToSave.contextMessages = messagesCount
            mainChatToSave.model = model
            await saveConversation(mainConversation)
        }
    }

    func queryConversations() async {
        await writeMainToDBIfNeeded()
        let chats = try! await Conversation.read(from: db, matching: \.$timeRemoved == 0 && \.$id != mainConversation.id, orderBy: .descending(\.$timeCreated))
        conversations = chats
    }

    func queryMessages(cid: String) async {
        messages = (try! await ChatMessage.read(from: db, matching: \.$conversationId == cid && \.$timeRemoved == 0, orderBy: .ascending(\.$timeCreated)))
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
}
