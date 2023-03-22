//
//  AddApiKeyView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import SwiftUI
import Alamofire

struct AddApiKeyView: View {
    @State var apiKey = ""
    @State var isValidating = false
    @State var error: AFError?

    let onValidateSuccess: () -> Void

    var body: some View {
        ZStack {
            VStack {
                Text("Add OpenAI API Key")
                    .font(.manrope(size: 28, weight: .bold))
                Spacer()
                    .frame(height: 40)
                TextField(text: $apiKey) {
                    Text("API key")
                }
                .font(.manrope(size: 18, weight: .medium))
                .padding(.init(top: 12, leading: 20, bottom: 12, trailing: 20))
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(.gray.opacity(0.1))
                }
                Text(LocalizedStringKey("[What's OpenAI API key?](https://platform.openai.com/account/api-keys)"))
                Spacer()
                    .frame(height: 60)
                Button(action: validateApiKey) {
                    if isValidating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 28, height: 28)
                            .frame(width: 260, height: 50)
                            .background(apiKey.isEmpty ? .gray.opacity(0.1) : .black)
                            .cornerRadius(25)
                            .tint(.white)

                    } else {
                        Text("Validate and Save")
                            .frame(width: 260, height: 50)
                            .background(apiKey.isEmpty ? .gray.opacity(0.1) : .black)
                            .cornerRadius(25)
                            .tint(.white)
                    }

                }
                .font(.manrope(size: 20, weight: .bold))
                .disabled(apiKey.isEmpty)

                if let error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .lineLimit(5)
                }

            }
            .padding(.horizontal, 20)
            .font(.manrope(size: 16, weight: .medium))
        }
    }

    func validateApiKey() {
        guard !isValidating else { return }
        error = nil
        isValidating = true
        Task {
            let result = await CatApi.validate(apiKey: apiKey)
            switch result {
            case .success(_):
                onValidateSuccess()
                UserDefaults.openApiKey = apiKey
            case .failure(let failure):
                error = failure
            }
            isValidating = false
        }

    }
}

struct AddApiKeyView_Previews: PreviewProvider {
    static var previews: some View {
        AddApiKeyView(onValidateSuccess: {})
    }
}
