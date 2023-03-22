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
        VStack {
            Text(conversation == nil ? "New Chat" : "Edit Chat")
                .font(.manrope(size: 28, weight: .bold))
            Spacer()
                .frame(height: 40)
            TextField(text: $title) {
                Text("Chat Name")
            }
            .tint(.black.opacity(0.8))
            .font(.manrope(size: 18, weight: .medium))
            .padding(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
            .frame(height: 50)
            .foregroundColor(.black.opacity(0.8))
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(.gray.opacity(0.1))
            }
            Spacer()
                .frame(height: 20)
            ZStack(alignment: .topLeading){
                if prompt.isEmpty {
                    Text("Prompt (the prompt content helps set the behavior of the assistant. e.g. 'You are Steve Jobs, the creator of Apple' )")
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.init(top: 18, leading: 24, bottom: 18, trailing: 20))
                        .allowsTightening(false)
                }
                if #available(iOS 16.0, *) {
                    TextEditor(text: $prompt)
                        .scrollContentBackground(.hidden)
                        .tint(.black.opacity(0.8))
                        .padding(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
                        .frame(height: 200)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .foregroundColor(.gray.opacity(0.1))
                        }
                } else {
                    TextEditor(text: $prompt)
                        .tint(.black.opacity(0.8))
                        .padding(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
                        .frame(height: 200)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .foregroundColor(.gray.opacity(0.1))
                        }.onAppear {
                            UITextView.appearance().backgroundColor = .clear
                        }
                }
            }
            .font(.manrope(size: 18, weight: .medium))
            .foregroundColor(.black.opacity(0.8))

            Spacer()
                .frame(height: 36)
            Button(action: { Task { await saveConversation() } }) {
                Text("Save")
                    .frame(width: 260, height: 50)
                    .background(title.isEmpty ? .black.opacity(0.1) : .black)
                    .cornerRadius(25)
                    .tint(.white)
            }
            .font(.manrope(size: 20, weight: .bold))
            .disabled(title.isEmpty)

        }
        .padding(.horizontal, 20)
        .onTapGesture {
            self.endEditing(force: true)
        }
        .font(.manrope(size: 16, weight: .medium))
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
