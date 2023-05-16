//
//  PushItem.swift
//  AICat
//
//  Created by Lei Pan on 2023/5/15.
//

import Foundation
import Blackbird

struct PushItem: BlackbirdModel {
    static var primaryKey: [BlackbirdColumnKeyPath] = [\.$id]

    @BlackbirdColumn var id: String = UUID().uuidString
    @BlackbirdColumn var type: String
    @BlackbirdColumn var itemObject: String
    @BlackbirdColumn var timeCreated: Int = Date.now.timeInSecond

    var itemDict: [String: Any] {
        let dict = try! JSONSerialization.jsonObject(with: itemObject.data(using: .utf8)!, options: []) as! [String: Any]
        return dict
    }
}
