//
//  Message.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Blackbird
import Foundation

struct ChatMessage: BlackbirdModel {
    static var primaryKey: [BlackbirdColumnKeyPath] = [\.$id]

    @BlackbirdColumn var id: String = UUID().uuidString
    @BlackbirdColumn var role: String
    @BlackbirdColumn var content: String
    @BlackbirdColumn var conversationId: String
    @BlackbirdColumn var replyToId: String = ""
    @BlackbirdColumn var model: String = "gpt-3.5-turbo"
    @BlackbirdColumn var timeCreated: Int = Date.now.timeInSecond
    @BlackbirdColumn var timeRemoved: Int = 0
}

extension ChatMessage {

    static func newSession(cid: String) -> ChatMessage {
        ChatMessage(role: "new_session", content: "", conversationId: cid)
    }

    var isNewSession: Bool {
        role == "new_session"
    }

    var isFromUser: Bool {
        role == "user"
    }
}
