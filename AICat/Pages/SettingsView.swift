//
//  SettingsView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/21.
//

import SwiftUI
import Foundation
import Alamofire

let models = [
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-0301",
    "gpt-4",
    "gpt-4-0314",
    "gpt-4-32k",
    "gpt-4-32k-0314"
]

let temperatures: [Double] = [
    0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0
]

struct SettingsView: View {

    @State var apiKey = UserDefaults.openApiKey ?? ""
    @State var isValidating = false
    @State var error: AFError?
    @State var isValidated = false
    @AppStorage("request.temperature") var temperature: Double = 1.0
    @AppStorage("request.context.messages") var messagesCount: Int = 0
    @AppStorage("request.model") var model: String = "gpt-3.5-turbo"

    var appVersion: String {
        Bundle.main.releaseVersion ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.buildNumber ?? "1"
    }

    let onClose: () -> Void

    var body: some View {
        VStack {
            #if os(iOS)
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                .tint(.primary)
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
            #endif
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
                            LoadingIndocator()
                                .frame(width: 24, height: 14)
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
                Section("Main Chat Settings") {
                    HStack {
                        Text("Model")
                        Picker("", selection: $model) {
                            ForEach(models, id: \.self) {
                                Text($0).lineLimit(1)
                            }
                        }.pickerStyle(.menu)
                    }
                    HStack {
                        Text("Temperature: \(String(format: "%.1f", temperature))")
                        Spacer()
                        Slider(value: $temperature, in: 0...1.0) {
                            Text("\(temperature)")
                        }.frame(width: 140)
                    }
                    Picker("Context messages", selection: $messagesCount) {
                        ForEach(0...10, id: \.self) { item in
                            Text("\(item)")
                        }
                    }.pickerStyle(.menu)
                }
                .menuStyle(.borderlessButton)
                Section("support") {
                    Link(destination: URL(string: "https://learnprompting.org/")!) {
                        Label("Learn Prompting", systemImage: "book")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://github.com/f/awesome-chatgpt-prompts")!) {
                        Label("Awesome chatgpt prompts", systemImage: "square.stack.3d.up")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://github.com/Panl/AICat.git")!){
                        Label("Source Code", systemImage: "ellipsis.curlybraces")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "mailto:iplay.coder@gmail.com")!){
                        Label("Contact Us", systemImage: "envelope.open")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://epochpro.app/aicat_privacy")!) {
                        Label("Privacy and Policy", systemImage: "lock.rectangle.on.rectangle")
                            .labelStyle(.titleAndIcon)
                    }
                }.tint(.primary)
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
                                Text("Guitar, Bass, Ukulele tuner, Metronome Practice Tracker")
                                    .font(.manrope(size: 12, weight: .regular))
                                    .multilineTextAlignment(.leading)
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
