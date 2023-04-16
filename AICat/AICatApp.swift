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
    @StateObject var appStateVM = AICatStateViewModel()
    
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
                .task {
                    await appStateVM.queryConversations()
                }
                .background(Color.background.ignoresSafeArea())
                .toast($appStateVM.saveImageToast)
                .overlay {
                   ShareMessagesImageOverlay()
                }
                .environmentObject(appStateVM)
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

        MenuBarExtra(
            content: {
                MainView()
                    .frame(width: 375, height: 720)
                    .task {
                        await appStateVM.queryConversations()
                    }
                    .environmentObject(appStateVM)
                    .background(Color.background.ignoresSafeArea())
            },
            label: {
                Image("chatgpt_logo_menu")
                    .renderingMode(.template)
                    .foregroundColor(.primaryColor)
            }
        )
        .menuBarExtraStyle(.window)
        #endif
    }
}
