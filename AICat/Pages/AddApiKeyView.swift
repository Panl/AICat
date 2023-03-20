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
                    .font(.custom("Avenir Next", size: 28))
                    .fontWeight(.bold)
                Spacer()
                    .frame(height: 40)
                TextField(text: $apiKey) {
                    Text("API key")
                }
                .font(.custom("Avenir Next", size: 18))
                .fontWeight(.medium)
                .padding(.init(top: 16, leading: 20, bottom: 10, trailing: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lineWidth: 1)
                        .foregroundColor(.gray.opacity(0.5))
                }
                Text(LocalizedStringKey("[What's OpenAI API key?](https://platform.openai.com/account/api-keys)"))
                    .font(.custom("Avenir Next", size: 16))
                    .fontWeight(.medium)
                    .tint(.teal)
                Spacer()
                    .frame(height: 60)
                Button(action: validateApiKey) {
                    if isValidating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 28, height: 28)
                            .frame(width: 260, height: 50)
                            .background(apiKey.isEmpty ? .black.opacity(0.1) : .black)
                            .cornerRadius(25)
                            .tint(.white)

                    } else {
                        Text("Validate and Save")
                            .frame(width: 260, height: 50)
                            .background(apiKey.isEmpty ? .black.opacity(0.1) : .black)
                            .cornerRadius(25)
                            .tint(.white)
                    }

                }
                .font(.custom("Avenir Next", size: 20))
                .fontWeight(.bold)
                .disabled(apiKey.isEmpty)

                if let error {
                    Text(error.localizedDescription)
                        .font(.custom("Avenir Next", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .lineLimit(5)
                }

            }.padding(.horizontal, 20)
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
