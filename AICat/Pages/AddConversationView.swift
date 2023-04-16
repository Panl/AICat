//
//  AddConversationView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import SwiftUI

struct AddConversationView: View {

    let conversation: Conversation?
    let onClose: () -> Void
    @State var title: String
    @State var prompt: String
    @EnvironmentObject var appStateVM: AICatStateViewModel
    @AppStorage("currentChat.id") var chatId: String?

    init(conversation: Conversation? = nil, onClose: @escaping () -> Void) {
        self.conversation = conversation
        self.onClose = onClose
        self.title = conversation?.title ?? ""
        self.prompt = conversation?.prompt ?? ""
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.borderless)
                .tint(.primaryColor)
            }.padding(20)
            Spacer(minLength: 56)
            Text(conversation == nil ? "New Chat" : "Edit Chat")
                .font(.manrope(size: 28, weight: .bold))
            Spacer()
                .frame(height: 40)
            TextField(text: $title) {
                Text("Chat Name")
            }
            .textFieldStyle(.plain)
            .tint(.primaryColor.opacity(0.8))
            .font(.manrope(size: 16, weight: .regular))
            .padding(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
            .frame(height: 50)
            .foregroundColor(.blackText.opacity(0.8))
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(.gray.opacity(0.1))
            }
            .padding(.horizontal, 20)

            Spacer()
                .frame(height: 20)
            ZStack(alignment: .topLeading){
                if prompt.isEmpty {
                    Text("Prompt (the prompt content helps set the behavior of the assistant. e.g. 'You are Steve Jobs, the creator of Apple' )")
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.init(top: 18, leading: 20, bottom: 18, trailing: 20))
                        .allowsTightening(false)
                }
                if #available(iOS 16.0, *) {
                    TextEditor(text: $prompt)
                        .scrollContentBackground(.hidden)
                        .tint(.primaryColor.opacity(0.8))
                        .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .frame(height: 200)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .foregroundColor(.gray.opacity(0.1))
                        }
                } else {
                    TextEditor(text: $prompt)
                        .tint(.primaryColor.opacity(0.8))
                        .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .frame(height: 200)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .foregroundColor(.gray.opacity(0.1))
                        }.onAppear {
                            #if os(iOS)
                            UITextView.appearance().backgroundColor = .clear
                            #endif
                        }
                }
            }
            .font(.manrope(size: 16, weight: .regular))
            .foregroundColor(.blackText.opacity(0.8))
            .padding(.horizontal, 20)

            Spacer()
                .frame(height: 36)
            Button(action: { Task { await saveConversation() } }) {
                Text("Save")
                    .frame(width: 260, height: 50)
                    .background(title.isEmpty ? .black.opacity(0.1) : .black)
                    .cornerRadius(25)
                    .tint(.white)
            }
            .buttonStyle(.borderless)
            .font(.manrope(size: 20, weight: .medium))
            .disabled(title.isEmpty)
            Spacer(minLength: 56)
        }
        .font(.manrope(size: 16, weight: .regular))
    }

    func saveConversation() async {
        guard !title.isEmpty else { return }
        if var conversation {
            conversation.title = title
            conversation.prompt = prompt
            await appStateVM.saveConversation(conversation)
            onClose()
        } else {
            let conversation = Conversation(title: title, prompt: prompt)
            await appStateVM.saveConversation(conversation)
            chatId = conversation.id
            onClose()
        }
    }
}


struct AddConversationView_Previews: PreviewProvider {
    static var previews: some View {
        AddConversationView(onClose: {})
    }
}
