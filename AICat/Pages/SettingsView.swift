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
    @State var apiHost = UserDefaults.apiHost
    @State var isValidating = false
    @State var error: AFError?
    @State var showApiKeyAlert = false
    @State var isValidated = false
    @State var isValidatingApiHost = false
    @State var isValidatedApiHost = false
    @State var apiHostError: AFError?
    @State var showApiHostAlert = false

    @EnvironmentObject var appStateVM: AICatStateViewModel

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
                Rectangle()
                    .frame(width: 16, height: 16)
                    .clipShape(Rectangle())
                    .hidden()
            }
            .padding(.horizontal, 20)
            .frame(height: 44)
            #endif
            List {
                if appStateVM.developMode {
                    Section("API Key") {
                        HStack {
                            SecureField(text: $apiKey) {
                                Text("Enter API key")
                            }
                            if !apiKey.isEmpty {
                                Button(action: {
                                    apiKey = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                }
                                .tint(.gray)
                                .buttonStyle(.borderless)
                            }
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
                        Button("Delete", action: {
                            apiKey = ""
                            UserDefaults.openApiKey = nil
                        })
                    }
                    .alert(
                        "Validate Failed",
                        isPresented: $showApiKeyAlert,
                        actions: {
                            Button("OK", action: { showApiKeyAlert = false })
                        },
                        message: {
                            Text("\(error?.localizedDescription ?? "")")
                        }
                    )
                    Section("API HOST") {
                        HStack {
                            TextField(text: $apiHost) {
                                Text("Enter api host")
                            }
                            if !apiHost.isEmpty {
                                Button(action: {
                                    apiHost = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                }
                                .tint(.gray)
                                .buttonStyle(.borderless)
                            }
                        }
                        HStack(spacing: 8) {
                            Button("Validate and save") {
                                validateApiHost()
                            }
                            if isValidatingApiHost {
                                LoadingIndocator()
                                    .frame(width: 24, height: 14)
                            }
                            if apiHostError != nil {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                            if isValidatedApiHost {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            Spacer()
                        }
                        Button("Reset", action: {
                            apiHost = "https://api.openai.com"
                            UserDefaults.apiHost = "https://api.openai.com"
                        })
                    }
                    .alert(
                        "Validate Failed",
                        isPresented: $showApiHostAlert,
                        actions: {
                            Button("OK", action: { showApiHostAlert = false })
                        },
                        message: {
                            Text("\(apiHostError?.localizedDescription ?? "")")
                        }
                    )
                }
                Section("support") {
                    Link(destination: URL(string: "https://learnprompting.org/")!) {
                        Label("Learn Prompting", systemImage: "book")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://github.com/f/awesome-chatgpt-prompts")!) {
                        Label("Awesome chatgpt prompts", systemImage: "square.stack.3d.up")
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
                Section("Source Code") {
                    Link(destination: URL(string: "https://github.com/Panl/AICat.git")!){
                        Label("AICat.git", image: "github_icon")
                            .labelStyle(.titleAndIcon)
                    }
                }.tint(.primary)
                Section("Social") {
                    Link(destination: URL(string: "https://t.me/aicatevents")!){
                        Label("AICat News", image: "telegram_icon")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://github.com/Panl")!){
                        Label("Panl", image: "github_icon")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://twitter.com/panlei106")!){
                        Label("Rego", image: "twitter_circled")
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
                            .gesture(
                                LongPressGesture()
                                    .onEnded { _ in
                                        appStateVM.developMode.toggle()
                                        HapticEngine.trigger()
                                    }
                            )
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
                showApiKeyAlert = true
            }
            isValidating = false
        }

    }

    func validateApiHost() {
        guard !isValidatingApiHost else { return }
        apiHostError = nil
        isValidatingApiHost = true
        isValidatedApiHost = false
        Task {
            let result = await CatApi.validate(apiHost: apiHost)
            switch result {
            case .success(_):
                UserDefaults.apiHost = apiHost
                isValidatedApiHost = true
            case .failure(let failure):
                apiHostError = failure
                showApiHostAlert = true
            }
            isValidatingApiHost = false
        }

    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(onClose: {})
            .environment(\.colorScheme, .light)
            .environmentObject(AICatStateViewModel())
    }
}
