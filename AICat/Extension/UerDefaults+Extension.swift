//
//  UerDefaults+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import Foundation
import CloudKit

let defaults = UserDefaults.standard

extension UserDefaults {

    var serverChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "server_change_token") as? Data else {
                return nil
            }
            guard let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data) else {
                return nil
            }
            return token
        }
        set {
            if let token = newValue {
                let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false)
                set(data, forKey: "server_change_token")
            } else {
                removeObject(forKey: "server_change_token")
            }
        }
    }

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
            defaults.double(forKey: "request.temperature")
        }
    }

    static var model: String {
        set {
            defaults.set(newValue, forKey: "request.model")
        }
        get {
            defaults.string(forKey: "request.model") ?? "gpt-3.5-turbo"
        }
    }

    static var apiHost: String {
        set {
            defaults.set(newValue, forKey: "AICat.apiHost")
        }
        get {
            openApiKey != nil ? (defaults.string(forKey: "AICat.apiHost") ?? "https://api.openai.com") : proxyAPIHost
        }
    }

    static var customApiHost: String {
        defaults.string(forKey: "AICat.apiHost") ?? "https://api.openai.com"
    }

    static func resetApiHost() {
        defaults.set(nil, forKey: "AICat.apiHost")
    }

    static func save(serverChangeToken: CKServerChangeToken?) {
        defaults.serverChangeToken = serverChangeToken
    }

    static func serverChangeToken() -> CKServerChangeToken? {
        return defaults.serverChangeToken
    }

}
