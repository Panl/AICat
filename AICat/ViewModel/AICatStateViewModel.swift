//
//  AICatStateViewModel.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/31.
//

import SwiftUI
import Combine
import Blackbird

let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/db.sqlite"

@MainActor class AICatStateViewModel: ObservableObject {
    var db = try! Blackbird.Database(path: dbPath, options: .debugPrintEveryQuery)
    @Published private(set) var conversations: [Conversation] = [mainConversation]
    @Published private(set) var currentConversation = mainConversation
    @Published private(set) var messages: [ChatMessage] = []

    var allConversations: [Conversation] {
        [mainConversation] + conversations
    }

    func queryConversations() async {
        // guard let db else { return }
        let chats = try! await Conversation.read(from: db, matching: \.$timeRemoved == 0, orderBy: .descending(\.$timeCreated))
        conversations = chats
    }

    func queryMessages(cid: String) async {
        // guard let db else { return }
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

    func setCurrentConversation(_ conversation: Conversation) {
        self.currentConversation = conversation
    }

    func resetMessages() {
        messages = []
    }
}
