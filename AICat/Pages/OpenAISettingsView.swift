//
//  OpenAISettingsView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/26.
//

import SwiftUI

class OpenAISettingsViewModel: ObservableObject {
    @Published
    var apiKey: String = UserDefaults.openApiKey ?? ""
    @Published
    var apiHost: String = UserDefaults.customApiHost
    @Published
    var isValidating: Bool = false
    @Published
    var error: Error?
    @Published
    var showApiKeyAlert: Bool = false
    @Published
    var isValidated: Bool = false
    @Published
    var toast: Toast?

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

    func resetApiHost() {
        apiHost = "https://api.openai.com"
        UserDefaults.resetApiHost()
        toast = Toast(type: .success, message: "ApiHost reset sucessful!")
    }

    func deleteApiKey() {
        apiKey = ""
        UserDefaults.openApiKey = nil
        toast = Toast(type: .success, message: "API Key deleted!")
    }
}

struct OpenAISettingsView: View {

    @ObservedObject var viewModel = OpenAISettingsViewModel()

    var body: some View {
        List {
            Section("API Key") {
                HStack {
                    SecureField(text: $viewModel.apiKey) {
                        Text("Enter API key")
                    }
                    .textFieldStyle(.automatic)
                    if !viewModel.apiKey.isEmpty {
                        Button(action: {
                            viewModel.apiKey = ""
                        }) {
                            Image(systemName: "multiply.circle.fill")
                        }
                        .tint(.gray)
                        .buttonStyle(.borderless)
                    }
                }
                Button("Delete", action: {
                    viewModel.deleteApiKey()
                })
            }
            .alert(
                "Validate Failed!",
                isPresented: $viewModel.showApiKeyAlert,
                actions: {
                    Button("OK", action: { viewModel.showApiKeyAlert = false })
                },
                message: {
                    Text("\(viewModel.error?.localizedDescription ?? "")")
                }
            )
            Section("API Host") {
                HStack {
                    TextField(text: $viewModel.apiHost) {
                        Text("Enter API host")
                    }
                    .textFieldStyle(.automatic)
                    if !viewModel.apiHost.isEmpty {
                        Button(action: {
                            viewModel.apiHost = ""
                        }) {
                            Image(systemName: "multiply.circle.fill")
                        }
                        .tint(.gray)
                        .buttonStyle(.borderless)
                    }
                }
                Button("Reset", action: {
                    viewModel.resetApiHost()
                })
            }

            HStack(spacing: 8) {
                Button("Validate and Save") {
                    viewModel.validateApi()
                }
                .disabled(viewModel.apiKey.isEmpty || viewModel.apiHost.isEmpty)
                if viewModel.isValidating {
                    LoadingIndocator()
                        .frame(width: 24, height: 14)
                }
                if viewModel.error != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
                if viewModel.isValidated {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                Spacer()
            }
        }
        .frame(minWidth: 350)
        .toast($viewModel.toast)
    }
}

struct OpenAISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAISettingsView()
    }
}
