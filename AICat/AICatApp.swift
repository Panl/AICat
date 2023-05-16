//
//  AICatApp.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird
import Foundation
import AppCenter
import AppCenterCrashes
import AppCenterAnalytics
import ApphudSDK

fileprivate let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/db.sqlite"
let mainConversation = Conversation(id: "AICat.Conversation.Main", title: "AICat Main", prompt: "")
let db = try! Blackbird.Database(path: dbPath, options: [])

@main
struct AICatApp: App {
    init() {
        AppCenter.start(
            withAppSecret: appCenterSecretKey,
            services: [
                Analytics.self,
                Crashes.self
            ]
        )
        Apphud.start(apiKey: appHudKey)
        DataStore.sync(complete: nil)
    }

    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            MainView()
                .background(Color.background.ignoresSafeArea())
        }
        #elseif os(macOS)
        WindowGroup {
            MainView()
                .frame(minWidth: 800, minHeight: 620)
                .background(Color.background.ignoresSafeArea())
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        Settings {
            SettingsView(onClose: {})
        }

        MenuBarExtra(
            content: {
                MainView()
                    .frame(width: 375, height: 720)
                    .background(Color.background.ignoresSafeArea())
            },
            label: {
                Image(systemName: "bubble.left.and.bubble.right")
                    .renderingMode(.template)
                    .foregroundColor(.primaryColor)
            }
        )
        .menuBarExtraStyle(.window)
        #endif
    }
}
