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
