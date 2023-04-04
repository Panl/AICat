//
//  Conversation.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Blackbird
import Foundation

struct Conversation: BlackbirdModel {
    static var primaryKey: [BlackbirdColumnKeyPath] = [\.$id]
    
    @BlackbirdColumn var id: String = UUID().uuidString
    @BlackbirdColumn var title: String
    @BlackbirdColumn var prompt: String
    @BlackbirdColumn var contextMessages: Int = 0
    @BlackbirdColumn var timeCreated: Int = Date.now.timeInSecond
    @BlackbirdColumn var timeRemoved: Int = 0

    var isMain: Bool {
        id == "AICat.Conversation.Main"
    }
}
