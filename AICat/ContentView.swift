//
//  ContentView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird

struct ContentView: View {

    @BlackbirdLiveModels({ try await Conversation.read(from: $0, matching: \.$title == "Mini Chat") }) var conversations

    var body: some View {
        ZStack {
//            if let conversation = conversations.results.first {
//                ConversationView(conversation: conversation)
//            } else {
//                AddConversation()
//            }
            ConversationView(conversation: Conversation(title: "Mini Chat", prompt: ""))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AddConversation: View {
    @Environment(\.blackbirdDatabase) var db

    @State var title: String = ""
    @State var prompt: String = ""
    var body: some View {
        ZStack {
            VStack {
                Text("New Conversation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                    .frame(height: 40)
                TextField(text: $title) {
                    Text("Conversation Name")
                }
                Spacer()
                    .frame(height: 10)
                TextField(text: $prompt) {
                    Text("Prompt")
                }
                Spacer()
                    .frame(height: 60)
                Button(action: {
                    Task {
                        try? await saveConversation()
                    }
                }) {
                    Text("Save")
                }
            }.padding(.horizontal, 20)
        }
    }

    func saveConversation() async throws {
        guard !title.isEmpty else { return }
        let conversation = Conversation(title: title, prompt: prompt)
        if let db {
            try await conversation.write(to: db)
        }
    }
}
