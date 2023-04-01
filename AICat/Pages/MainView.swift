//
//  MainView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/24.
//

import SwiftUI
import Blackbird

let mainConversation = Conversation(id: "AICat.Conversation.Main", title: "AICat Main", prompt: "")

struct MainView: View {

    
    @State var showAddAPIKeySheet = false

    @AppStorage("openApiKey")
    var apiKey: String?

    @StateObject var appStateVM = AICatStateViewModel()

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > 560 {
                SplitView(size: proxy.size)
            } else {
                CompactView()
            }
        }
        .task {
            await appStateVM.queryConversations()
        }
        .environmentObject(appStateVM)
        .sheet(isPresented: $showAddAPIKeySheet) {
            AddApiKeyView(
                onValidateSuccess: { showAddAPIKeySheet = false },
                onSkip: { showAddAPIKeySheet = false }
            )
        }
        .onAppear {
//            if apiKey == nil {
//                showAddAPIKeySheet = true
//            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
