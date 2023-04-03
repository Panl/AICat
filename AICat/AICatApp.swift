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

@main
struct AICatApp: App {
    @StateObject var appStateVM = AICatStateViewModel()
    
    init() {
        AppCenter.start(
            withAppSecret: appCenterSecretKey,
            services: [
                Analytics.self,
                Crashes.self
            ]
        )
    }

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            MainView()
                .task {
                    await appStateVM.queryConversations()
                }
                .environmentObject(appStateVM)
                .background(Color.background.ignoresSafeArea())
            #elseif os(macOS)
            MacMainView()
                .task {
                    await appStateVM.queryConversations()
                }
                .environmentObject(appStateVM)
                .background(Color.background.ignoresSafeArea())
            #endif
        }
        Settings {
            SettingsView(onClose: {})
                .environmentObject(appStateVM)
        }
        MenuBarExtra("AICat Main", systemImage: "bubble.left.fill") {
            MenuBarApp()
                .environmentObject(appStateVM)
        }
        .menuBarExtraStyle(.window)
        .keyboardShortcut("M", modifiers: .command)
    }
}
