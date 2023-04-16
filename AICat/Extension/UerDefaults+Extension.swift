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
            defaults.string(forKey: "AICat.apiHost") ?? (isDeveloperModeEnable ? "https://api.openai.com" : proxyAPIHost)
        }
    }

    static var isDeveloperModeEnable: Bool {
        defaults.bool(forKey: "AICat.developerMode") || openApiKey != nil
    }

    static func resetApiHost() {
        defaults.set(nil, forKey: "AICat.apiHost")
    }

}
