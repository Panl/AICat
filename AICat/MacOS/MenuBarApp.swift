//
//  MenuBarApp.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/4.
//

import SwiftUI

struct MenuBarApp: View {
    var body: some View {
        NavigationStack {
            ConversationView(conversation: mainConversation, showToolbar: false, onChatsClick: {})
                .frame(width: 375, height: 700)
                .background(Color.background)
                .navigationTitle(mainConversation.title)
        }.toolbar {
            Image(systemName: "ellipsis")
                .frame(width: 24, height: 24)
                .clipShape(Rectangle())
        }
    }
}

struct MenuBarApp_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarApp()
    }
}
