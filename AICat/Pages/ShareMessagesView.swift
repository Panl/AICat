//
//  ShareMessagesView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/16.
//

import SwiftUI

struct ShareMessagesView: View {

    var title: String = "AICat Main"
    var prompt: String = "Your ultimate AI assistant"
    var messages: [ChatMessage] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.manrope(size: 18, weight: .bold))
                .foregroundColor(.primaryColor)
                .lineLimit(1)
                .padding(.horizontal, 20)
                .padding(.top)
            Text(prompt)
                .font(.manrope(size: 10, weight: .regular))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .lineLimit(1)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.2))
                .padding(.horizontal)
            Spacer().frame(height: 20)
            VStack(alignment: .leading, spacing: 20) {
                ForEach(messages, id: \.id) {
                    MessageView(message: $0)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer().frame(height: 40)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.2))
                .padding(.horizontal)
            HStack(spacing: 8) {
                Image("aicat_logo")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                    .padding(.leading)
                VStack(alignment: .leading) {
                    Text("AICat")
                        .font(.manrope(size: 16, weight: .bold))
                        .foregroundColor(.primary.opacity(0.7))
                    Text("Your ultimate AI assistant")
                        .font(.manrope(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                Spacer()
                Image("aicat_qrcode")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }
        }
        .background(Color.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 1)
        .padding()
        .frame(width: screenSize().width)
        .ignoresSafeArea()
    }
}

struct ShareMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        ShareMessagesView(
            messages: [
                ChatMessage(role: "user", content: "hello world", conversationId: "id"),
                ChatMessage(role: "ot", content: "hello world hello world hello world hello world hello world", conversationId: "id"),
                ChatMessage(role: "user", content: "hello world", conversationId: "id"),
                ChatMessage(role: "ot", content: "hello world hello world hello world hello world hello world", conversationId: "id"),
                ChatMessage(role: "user", content: "hello world", conversationId: "id"),
                ChatMessage(role: "ot", content: "hello world hello world hello world hello world hello world", conversationId: "id")
            ]
        )
        .environmentObject(AICatStateViewModel())
            .environment(\.colorScheme, .light)
    }
}
