//
//  Message.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Blackbird
import Foundation
import CloudKit

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

    static func from(record: CKRecord) -> ChatMessage {
        var m = ChatMessage(role: "", content: "", conversationId: "")
        m.id = record["id"] as! String
        m.role = record["role"] as! String
        m.content = record["content"] as! String
        m.conversationId = record["conversationId"] as! String
        m.replyToId = record["replyToId"] as! String
        m.model = record["model"] as! String
        m.timeCreated = record["timeCreated"] as! Int
        m.timeRemoved = record["timeRemoved"] as! Int
        return m
    }
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

    var recordDict: [String: Any] {
        return [
            "id": id,
            "role": role,
            "content": content,
            "conversationId": conversationId,
            "replyToId": replyToId,
            "model": model,
            "timeCreated": timeCreated,
            "timeRemoved": timeRemoved
        ]
    }

    var json: String {
        let jsonData = try! JSONSerialization.data(withJSONObject: recordDict, options: [])
        return String(bytes: jsonData, encoding: .utf8)!
    }
}

extension ChatMessage: Recordable {}

extension ChatMessage: Pushable {
    var recordId: String {
        id
    }

    var recordType: RecordType {
        .chatMessage
    }
}
