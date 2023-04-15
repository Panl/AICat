//
//  MainView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/24.
//

import SwiftUI
import Blackbird

struct MainView: View {

    
    @EnvironmentObject var appStateVM: AICatStateViewModel

    @AppStorage("openApiKey")
    var apiKey: String?

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > 560 {
                SplitView(size: proxy.size)
            } else {
                CompactView()
            }
        }
        .sheet(isPresented: $appStateVM.showAddAPIKeySheet) {
            AddApiKeyView(
                onValidateSuccess: { appStateVM.showAddAPIKeySheet = false },
                onSkip: { appStateVM.showAddAPIKeySheet = false }
            )
        }
        .sheet(isPresented: $appStateVM.showPremumPage) {
            PremiumPage()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
