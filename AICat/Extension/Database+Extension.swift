//
//  Database+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import Blackbird
import CloudKit

extension Blackbird.Database {

    func upsert(model: some BlackbirdModel) async {
        do {
            try await model.write(to: self)
        } catch {
            debugPrint(error)
        }
    }

    func upsert(item: any PushableObject) async {
        do {
            try await item.write(to: self)
            try await item.toPushItem().write(to: self)
        } catch {
            debugPrint(error)
        }
    }

    func delete(items: [PushItem]) async {
        do {
            for item in items {
                try await item.delete(from: db)
            }
        } catch {
            debugPrint(error)
        }
    }

    func queryPushItems() async -> [PushItem] {
        do {
            return try await PushItem.read(from: self, orderBy: .ascending(\.$timeCreated))
        } catch {
            debugPrint(error)
            return []
        }
    }

    func save(records: [CKRecord]) async {
        var objs: [any BlackbirdModel] = []
        for record in records {
            let type = record.recordType
            if let recordType = RecordType(rawValue: type) {
                let obj: any BlackbirdModel
                switch recordType {
                case .conversation:
                    obj = Conversation.from(record: record)
                case .chatMessage:
                    obj = ChatMessage.from(record: record)
                }
                objs.append(obj)
            }
        }
        for obj in objs {
            do {
                try await obj.write(to: self)
            } catch {
                debugPrint(error)
            }
        }
    }

    func allPushableToPushItems() async -> [PushItem] {
        do {
            let conversations = try await Conversation.read(from: self, orderBy: .ascending(\.$timeCreated))
            let messages = try await ChatMessage.read(from: self, orderBy: .ascending(\.$timeCreated))
            var preMsg: ChatMessage?
            let fixedTimeMessages = messages.map { message in
                var msg = message
                if let preMsg, preMsg.timeCreated == msg.timeCreated {
                    msg.timeCreated += 1
                }
                preMsg = message
                return msg
            }
            return conversations.map { $0.toPushItem() } + fixedTimeMessages.map { $0.toPushItem() }
        } catch {
            debugPrint(error)
            return []
        }
    }
}
