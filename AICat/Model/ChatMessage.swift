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
    @BlackbirdColumn var timeCreated: Int = Date.now.timeInSecond
    @BlackbirdColumn var timeRemoved: Int = 0
}
