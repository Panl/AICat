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
        #if os(iOS)
        WindowGroup {
            MainView()
                .task {
                    await appStateVM.queryConversations()
                }
                .environmentObject(appStateVM)
                .background(Color.background.ignoresSafeArea())
        }
        #elseif os(macOS)
        WindowGroup {
            MainView()
                .task {
                    await appStateVM.queryConversations()
                }
                .environmentObject(appStateVM)
                .background(Color.background.ignoresSafeArea())
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        Settings {
            SettingsView(onClose: {})
                .environmentObject(appStateVM)
        }
        MenuBarExtra("AICat Main", systemImage: "bubble.left.and.bubble.right.fill") {
            MainView()
                .frame(width: 375, height: 720)
                .task {
                    await appStateVM.queryConversations()
                }
                .environmentObject(appStateVM)
                .background(Color.background.ignoresSafeArea())
        }
        .menuBarExtraStyle(.window)
        .keyboardShortcut("M", modifiers: .command)
        #endif
    }
}
