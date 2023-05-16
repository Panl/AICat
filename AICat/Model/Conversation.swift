//
//  Conversation.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Blackbird
import Foundation
import CloudKit

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

    static func from(record: CKRecord) -> Conversation {
        var c = Conversation(title: "", prompt: "")
        c.id = record["id"] as! String
        c.title = record["title"] as! String
        c.prompt = record["prompt"] as! String
        c.contextMessages = record["contextMessages"] as! Int
        c.temperature = record["temperature"] as! Double
        c.model = record["model"] as! String
        c.maxTokens = record["maxTokens"] as! Int
        c.topP = record["topP"] as! Double
        c.presencePenalty = record["presencePenalty"] as! Double
        c.frequencyPenalty = record["frequencyPenalty"] as! Double
        c.cost = record["cost"] as! Double
        c.timeCreated = record["timeCreated"] as! Int
        c.timeRemoved = record["timeRemoved"] as! Int
        return c
    }

}

extension Conversation: Pushable {
    var recordId: String {
        id
    }

    var recordType: RecordType {
        .conversation
    }

    var recordDict: [String : Any] {
        [
            "id": id,
            "title": title,
            "prompt": prompt,
            "contextMessages": contextMessages,
            "temperature": temperature,
            "model": model,
            "maxTokens": maxTokens,
            "topP": topP,
            "presencePenalty": presencePenalty,
            "frequencyPenalty": frequencyPenalty,
            "cost": cost,
            "timeCreated": timeCreated,
            "timeRemoved": timeRemoved
        ]
    }

    var json: String {
        let jsonData = try! JSONSerialization.data(withJSONObject: recordDict, options: [])
        return String(bytes: jsonData, encoding: .utf8)!
    }
}

extension Conversation: Recordable {}
