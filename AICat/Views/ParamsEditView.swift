//
//  ParamsEditView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/7.
//

import SwiftUI

let contextCounts: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 50, 100]

let models = [
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-0301",
    "gpt-4",
    "gpt-4-0314",
    "gpt-4-32k",
    "gpt-4-32k-0314"
]

// https://platform.openai.com/docs/api-reference/completions/create

struct ParamsEditView: View {

    @EnvironmentObject var appStateVM: AICatStateViewModel

    @State var conversation: Conversation
    @State var temperature: Double = 0.7

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            HStack {
                Text("Context Messages")
                    .padding(.leading, 10)
                Spacer()
                Picker("", selection: $conversation.contextMessages) {
                    ForEach(contextCounts, id: \.self) {
                        Text("\($0)")
                    }
                }
                .pickerStyle(.menu)
                .tint(.primaryColor.opacity(0.6))
            }
            .padding(.vertical, 4)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(lineWidth: 1)
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 12)
            HStack {
                Text("Model")
                    .padding(.leading, 10)
                Spacer()
                Picker("", selection: $conversation.model) {
                    ForEach(models, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primaryColor.opacity(0.6))
            }
            .padding(.vertical, 4)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(lineWidth: 1)
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            VStack(spacing: 12) {
                HStack {
                    Text("Temperature")
                    Spacer()
                    Text(String(format: "%.2f", conversation.temperature))
                }
                .padding(.horizontal, 12)
                SliderView(value: $conversation.temperature, sliderRange: 0...2)
                    .frame(height: 20)
            }.padding(.horizontal, 10)

            VStack(spacing: 12) {
                HStack {
                    Text("Top P")
                    Spacer()
                    Text(String(format: "%.2f", conversation.topP))
                }
                .padding(.horizontal, 12)
                SliderView(value: $conversation.topP, sliderRange: 0...1)
                    .frame(height: 20)
            }.padding(.horizontal, 10)

            VStack(spacing: 12) {
                HStack {
                    Text("Frequency penalty")
                    Spacer()
                    Text(String(format: "%.2f", conversation.frequencyPenalty))
                }
                .padding(.horizontal, 12)
                SliderView(value: $conversation.frequencyPenalty, sliderRange: -2...2)
                    .frame(height: 20)
            }.padding(.horizontal, 10)

            VStack(spacing: 12) {
                HStack {
                    Text("Presence penalty")
                    Spacer()
                    Text(String(format: "%.2f", conversation.presencePenalty))
                }
                .padding(.horizontal, 12)
                SliderView(value: $conversation.presencePenalty, sliderRange: -2...2)
                    .frame(height: 20)
            }.padding(.horizontal, 10)
            Spacer()
        }
        .padding(.horizontal, 20)
        .font(.manrope(size: 16, weight: .medium))
        .foregroundColor(.blackText)
        .onChange(of: conversation) { newValue in
            Task {
                await appStateVM.saveConversation(newValue)
            }
        }
    }
}

struct ParamsEditView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            ParamsEditView(conversation: Conversation(title: "Main", prompt: ""))
        }.environment(\.colorScheme, .light)
    }
}
