//
//  AddConversationView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import SwiftUI

struct AddConversationView: View {
    @Environment(\.blackbirdDatabase) var db

    let conversation: Conversation?
    let onSave: (Conversation) -> Void
    @State var title: String
    @State var prompt: String

    init(conversation: Conversation? = nil, onSave: @escaping (Conversation) -> Void) {
        self.conversation = conversation
        self.onSave = onSave
        self.title = conversation?.title ?? ""
        self.prompt = conversation?.prompt ?? ""
    }


    var body: some View {
        ZStack {
            VStack {
                Text(conversation == nil ? "New Chat" : "Edit Chat")
                    .font(.custom("Avenir Next", size: 28))
                    .fontWeight(.bold)
                Spacer()
                    .frame(height: 40)
                TextField(text: $title) {
                    Text("Chat Name")
                }
                .font(.custom("Avenir Next", size: 18))
                .fontWeight(.medium)
                .padding(.init(top: 16, leading: 20, bottom: 10, trailing: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lineWidth: 1)
                        .foregroundColor(.gray.opacity(0.5))
                }
                Spacer()
                    .frame(height: 20)
                TextField(text: $prompt) {
                    Text("Prompt")
                }
                .font(.custom("Avenir Next", size: 19))
                .fontWeight(.medium)
                .padding(.init(top: 16, leading: 20, bottom: 10, trailing: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lineWidth: 1)
                        .foregroundColor(.gray.opacity(0.5))
                }
                Spacer()
                    .frame(height: 60)
                Button(action: { Task { await saveConversation() } }) {
                    Text("Save")
                        .frame(width: 260, height: 50)
                        .background(title.isEmpty ? .black.opacity(0.1) : .black)
                        .cornerRadius(25)
                        .tint(.white)
                }
                .font(.custom("Avenir Next", size: 20))
                .fontWeight(.bold)
                .disabled(title.isEmpty)

            }.padding(.horizontal, 20)
        }
    }

    func saveConversation() async {
        guard !title.isEmpty else { return }
        if var conversation {
            conversation.title = title
            conversation.prompt = prompt
            await db?.upsert(model: conversation)
            onSave(conversation)
        } else {
            let conversation = Conversation(title: title, prompt: prompt)
            await db?.upsert(model: conversation)
            onSave(conversation)
        }

    }
}


struct AddConversationView_Previews: PreviewProvider {
    static var previews: some View {
        AddConversationView(onSave: { _ in})
    }
}
