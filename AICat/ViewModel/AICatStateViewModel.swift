//
//  AICatStateViewModel.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/31.
//

import SwiftUI
import Combine
import Blackbird
import ApphudSDK
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

fileprivate let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/db.sqlite"
let mainConversation = Conversation(id: "AICat.Conversation.Main", title: "AICat Main", prompt: "")
let db = try! Blackbird.Database(path: dbPath, options: [])

@MainActor class AICatStateViewModel: NSObject, ObservableObject {
    @Published var monthlyPremium: ApphudProduct?

    @AppStorage("request.temperature") var temperature: Double = 1.0
    @AppStorage("request.context.messages") var messagesCount: Int = 0
    @AppStorage("request.model") var model: String = "gpt-3.5-turbo"
    @AppStorage("db.conversations.didMigrateParams") var didMigrateParams: Bool = false
    @AppStorage("AICat.developerMode") var developMode: Bool = false

    @Published var sentMessageCount: Int64 = 0
    @Published var shareMessagesSnapshot: ImageType?
    @Published var saveImageToast: Toast?

    var freeMessageCount: Int64 {
        #if DEBUG
        return 5
        #else
        return 20
        #endif
    }

    private var cancellable: AnyCancellable?

    override init() {
        super.init()
        NSUbiquitousKeyValueStore.default.synchronize()
        cancellable = NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] _ in
                self?.fetchValueFromICloud()
            }
        fetchValueFromICloud()
    }

    func fetchValueFromICloud() {
        let value = NSUbiquitousKeyValueStore.default.longLong(forKey: "AICat.sentMessageCount")
        sentMessageCount = value
    }

    func incrementSentMessageCount() {
        sentMessageCount += 1
        if sentMessageCount > freeMessageCount {
            sentMessageCount = freeMessageCount
        }
        let keyValueStore = NSUbiquitousKeyValueStore.default
        keyValueStore.set(sentMessageCount, forKey: "AICat.sentMessageCount")
        keyValueStore.synchronize()
    }


    var isPremium: Bool {
        UserDefaults.openApiKey != nil || Apphud.hasPremiumAccess()
    }

    var isDeveloperModeEnable: Bool {
        UserDefaults.openApiKey != nil || developMode
    }

    private var hasPremiumAccess: Bool {
        if let subscription = Apphud.subscription() {
            if subscription.isActive() {
                if !subscription.isSandbox {
                    return true
                }
                if subscription.isSandbox && SystemUtil.maybeFromTestFlight {
                    return true
                }
            }
            return false
        }
        return false
    }

    func fetchPayWall() async {
        if let payWall = await Apphud.paywalls().first, let product = payWall.products.first {
            monthlyPremium = product
        }
    }

    func needBuyPremium() -> Bool {
        if !isPremium && sentMessageCount >= freeMessageCount {
            return true
        }
        return false
    }
}
