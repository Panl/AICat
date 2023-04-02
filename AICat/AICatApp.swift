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
            MainView()
                .background(Color.background.ignoresSafeArea())
        }
    }
}
