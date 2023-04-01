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
    @AppStorage("request.temperature") var temperature: Double = 1.0
    @AppStorage("request.context.messages") var messagesCount: Int = 0

    var appVersion: String {
        Bundle.main.releaseVersion ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.buildNumber ?? "1"
    }

    let onClose: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .tint(.primary)
                        .frame(width: 24, height: 24)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text("Settings")
                        .foregroundColor(.blackText)
                        .font(.manrope(size: 18, weight: .bold))
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
                    SecureField(text: $apiKey) {
                        Text("Enter API key")
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
                        Text("Temperature: \(String(format: "%.1f", temperature))")
                        Spacer()
                        Slider(value: $temperature, in: 0...1.0) {
                            Text("\(temperature)")
                        }.frame(width: 140)
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
                Section("support") {
                    Link(destination: URL(string: "https://learnprompting.org/")!) {
                        Label("Learn Prompting", systemImage: "book")
                            .labelStyle(.titleAndIcon)
                    }.tint(.primary)
                    Link(destination: URL(string: "https://github.com/f/awesome-chatgpt-prompts")!) {
                        Label("Awesome chatgpt prompts", systemImage: "square.stack.3d.up")
                            .labelStyle(.titleAndIcon)
                    }.tint(.primary)
                    Link(destination: URL(string: "https://github.com/Panl/AICat.git")!){
                        Label("Source Code", systemImage: "ellipsis.curlybraces")
                            .labelStyle(.titleAndIcon)
                    }.tint(.primary)
                    Button(action: {
                        UIApplication.shared.open(URL(string: "mailto:iplay.coder@gmail.com")!)
                    }) {
                        Label("Contact Us", systemImage: "envelope.open")
                            .labelStyle(.titleAndIcon)
                    }.tint(.primary)
                    Link(destination: URL(string: "https://epochpro.app/aicat_privacy")!) {
                        Label("Privacy and Policy", systemImage: "checkmark.shield")
                            .labelStyle(.titleAndIcon)
                    }.tint(.primary)
                }
                Section(
                    header: Text("More App"),
                    footer: HStack {
                        Spacer()
                        Text("AICat \(appVersion)(\(buildNumber))")
                            .font(.manrope(size: 12, weight: .regular))
                            .padding(12)
                        Spacer()
                    }) {
                    Link(destination: URL(string: "https://apps.apple.com/app/epoch-music-toolkit/id1459345397")!) {
                        HStack(spacing: 12) {
                            Image("icon_epoch")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .cornerRadius(8)
                            VStack(alignment: .leading) {
                                Text("Epoch - Guitar Tuner")
                                    .font(.manrope(size: 14, weight: .medium))
                                Text("Guitar, Bass, Ukulele tuner, Metronome\n Practice Tracker")
                                    .font(.manrope(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }.padding(.vertical, 4)
                    }.tint(.primary)
                }
            }
            .background(Color.background)
            .font(.manrope(size: 16, weight: .medium))
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
