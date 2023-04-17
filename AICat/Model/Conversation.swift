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
    @BlackbirdColumn var contextMessages: Int = 5
    @BlackbirdColumn var temperature: Double = 0.7
    @BlackbirdColumn var model: String = "gpt-3.5-turbo"
    @BlackbirdColumn var maxTokens: Int = 2048
    @BlackbirdColumn var topP: Double = 1
    @BlackbirdColumn var presencePenalty: Double = 0
    @BlackbirdColumn var frequencyPenalty: Double = 0
    @BlackbirdColumn var cost: Double = 0
    @BlackbirdColumn var timeCreated: Int = Date.now.timeInSecond
    @BlackbirdColumn var timeRemoved: Int = 0

    var isMain: Bool {
        id == "AICat.Conversation.Main"
    }
}
