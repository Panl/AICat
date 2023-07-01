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
    @State var error: Error?
    @State var showApiKeyAlert = false
    @State var isValidated = false
    @State var toast: Toast?

    var body: some View {
        List {
            Section("API Key") {
                HStack {
                    SecureField(text: $apiKey) {
                        Text("Enter API key")
                    }
                    .textFieldStyle(.automatic)
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
            Section("API Host") {
                HStack {
                    TextField(text: $apiHost) {
                        Text("Enter API host")
                    }
                    .textFieldStyle(.automatic)
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
                Button("Reset", action: {
                    apiHost = "https://api.openai.com"
                    UserDefaults.resetApiHost()
                    toast = Toast(type: .success, message: "ApiHost reset sucessful!")
                })
            }

            HStack(spacing: 8) {
                Button("Validate and Save") {
                    validateApi()
                }
                .disabled(apiKey.isEmpty || apiHost.isEmpty)
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
                Spacer()
            }
        }
        .frame(minWidth: 350)
        .toast($toast)

    }

    func validateApi() {
        guard !isValidating else { return }
        error = nil
        isValidating = true
        isValidated = false
        Task {
            do {
                let _ = try await CatApi.validate(apiHost: apiHost, apiKey: apiKey)
                UserDefaults.apiHost = apiHost
                UserDefaults.openApiKey = apiKey
                isValidated = true
            } catch {
                self.error = error
                showApiKeyAlert = true
            }
            isValidating = false
        }

    }
}

struct OpenAISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAISettingsView()
    }
}
