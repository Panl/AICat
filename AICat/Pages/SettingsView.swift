//
//  SettingsView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/21.
//

import SwiftUI
import Foundation
import Alamofire

struct SettingsView: View {

    @State var apiKey = UserDefaults.openApiKey ?? ""
    @State var isValidating = false
    @State var error: AFError?
    @State var isValidated = false
    @AppStorage("currentChat.id") var chatId: String?
    @AppStorage("request.temperature") var temperature: Double = 1
    @AppStorage("request.context.messages") var messagesCount: Int = 0


    let temperatureConfig: [Double: String] = [
        0.2: "Divergent",
        1.0: "Balanced",
        1.8: "Deterministic"
    ]

    let onClose: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .tint(.black)
                        .frame(width: 24, height: 24)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text("Settings")
                        .font(.custom("Avenir Next", size: 16))
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .frame(width: 24, height: 24)
                    .clipShape(Rectangle())
                    .hidden()
            }
            .padding(.horizontal, 20)
            .frame(height: 44)
            List {
                Section("API Key") {
                    TextField(text: $apiKey) {
                        Text("input api ley")
                    }
                    HStack(spacing: 8) {
                        Button("Validate and save") {
                            validateApiKey()
                        }
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        if error != nil {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                        if isValidated {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                Section("Request Settings") {
                    HStack {
                        Text("Model")
                        Spacer()
                        Menu("gpt-3.5-turbo") {}
                    }
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Menu {
                            Button("Divergent") {
                                temperature = 0.2
                            }
                            Button("Balance") {
                                temperature = 1.0
                            }
                            Button("Deterministic") {
                                temperature = 1.8
                            }
                        } label: {
                            HStack {
                                Text(temperatureConfig[temperature] ?? "None")
                                Image(systemName: "chevron.up.chevron.down")
                            }
                        }
                    }
                    HStack {
                        Text("Context Messages")
                        Spacer()
                        Menu {
                            ForEach(0...10, id: \.self) { item in
                                Button("\(item)") {
                                    messagesCount = item
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(messagesCount)")
                                Image(systemName: "chevron.up.chevron.down")
                            }
                        }
                    }
                }
//                Section("support") {
//                    Button(action: {}) {
//                        Label("Share AICat", systemImage: "square.and.arrow.up")
//                            .labelStyle(.titleAndIcon)
//                    }.tint(.black)
//                    Button(action: {}) {
//                        Label("Contact Us", systemImage: "envelope")
//                            .labelStyle(.titleAndIcon)
//                    }.tint(.black)
//                    Button(action: {}) {
//                        Label("Privacy and Policy", systemImage: "person.badge.shield.checkmark")
//                            .labelStyle(.titleAndIcon)
//                    }.tint(.black)
//                }
            }
            .font(.custom("Avenir Next", size: 16))
            .fontWeight(.medium)
        }
    }

    func validateApiKey() {
        guard !isValidating else { return }
        error = nil
        isValidating = true
        isValidated = false
        Task {
            let result = await CatApi.validate(apiKey: apiKey)
            switch result {
            case .success(_):
                UserDefaults.openApiKey = apiKey
                isValidated = true
            case .failure(let failure):
                error = failure
            }
            isValidating = false
        }

    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(onClose: {})
    }
}
