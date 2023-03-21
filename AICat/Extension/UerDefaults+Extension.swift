//
//  UerDefaults+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import Foundation

let defaults = UserDefaults.standard


extension UserDefaults {

    static var openApiKey: String? {
        set {
            defaults.set(newValue, forKey: "openApiKey")
        }
        get {
            defaults.string(forKey: "openApiKey")
        }
    }

    static var temperature: Double {
        set {
            defaults.set(newValue, forKey: "request.temperature")
        }
        get {
            let value = defaults.double(forKey: "request.temperature")
            if value == 0 {
                return 1
            } else {
                return value
            }
        }
    }

}
