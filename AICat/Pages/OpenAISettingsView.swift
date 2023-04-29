//
//  OpenAISettingsView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/26.
//

import SwiftUI
import Alamofire

struct OpenAISettingsView: View {

    @State var apiKey = UserDefaults.openApiKey ?? ""
    @State var apiHost = UserDefaults.customApiHost
    @State var isValidating = false
    @State var error: AFError?
    @State var showApiKeyAlert = false
    @State var isValidated = false
    @State var isValidatingApiHost = false
    @State var isValidatedApiHost = false
    @State var apiHostError: AFError?
    @State var showApiHostAlert = false
    @State var toast: Toast?

    var body: some View {
        List {
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
                    Button("Validate and Save") {
                        validateApiKey()
                    }
                    .disabled(apiKey.isEmpty)
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
                    toast = Toast(type: .success, message: "API Key deleted!")
                })
            }
            .alert(
                "Validate Failed!",
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
                    Button("Validate and Save") {
                        validateApiHost()
                    }
                    .disabled(apiKey.isEmpty)
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
                    UserDefaults.resetApiHost()
                    toast = Toast(type: .success, message: "ApiHost reset sucessful!")
                })
            }
            .alert(
                "Validate Failed!",
                isPresented: $showApiHostAlert,
                actions: {
                    Button("OK", action: { showApiHostAlert = false })
                },
                message: {
                    Text("\(apiHostError?.localizedDescription ?? "")")
                }
            )
        }
        .toast($toast)

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
            let result = await CatApi.validate(apiHost: apiHost, apiKey: apiKey)
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

struct OpenAISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAISettingsView()
    }
}
