//
//  AddApiKeyView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import SwiftUI
import Alamofire

struct AddApiKeyView: View {
    @State var apiKey = UserDefaults.openApiKey ?? ""
    @State var isValidating = false
    @State var error: AFError?
    @State private var isSecured: Bool = true

    let onValidateSuccess: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onSkip) {
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.borderless)
                .tint(.primaryColor)
            }.padding(20)
            Spacer(minLength: 56)
            Text("Add OpenAI API Key")
                .font(.manrope(size: 28, weight: .bold))
            Spacer()
                .frame(height: 40)
            ZStack(alignment: .trailing) {
                Group {
                    if isSecured {
                        SecureField("Enter API Key", text: $apiKey)
                    } else {
                        TextField("Enter API Key", text: $apiKey)
                    }
                }
                .textFieldStyle(.plain)
                .tint(.primary.opacity(0.8))
                .font(.manrope(size: 18, weight: .regular))
                .padding(.trailing, 32)
                Button(action: {
                    isSecured.toggle()
                }) {
                    Image(systemName: self.isSecured ? "eye.slash" : "eye")
                        .accentColor(.gray)
                }.buttonStyle(.borderless)
            }
            .frame(minWidth: 280)
            .padding(.init(top: 12, leading: 20, bottom: 12, trailing: 20))
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(.gray.opacity(0.1))
            }
            .padding(.horizontal, 40)
            .onTapGesture {

            }

            Text(LocalizedStringKey("[Where to get OpenAI API key?](https://platform.openai.com/account/api-keys)"))
            Spacer()
                .frame(height: 60)
            Button(action: validateApiKey) {
                if isValidating {
                    LoadingIndocator(themeColor: .whiteText)
                        .frame(width: 28, height: 28)
                        .frame(width: 260, height: 50)
                        .background(apiKey.isEmpty ? Color.primaryColor.opacity(0.4) : Color.primaryColor)
                        .cornerRadius(25)
                } else {
                    Text("Validate and Save")
                        .frame(width: 260, height: 50)
                        .background(apiKey.isEmpty ? Color.primaryColor.opacity(0.4) : Color.primaryColor)
                        .cornerRadius(25)
                }

            }
            .tint(.whiteText)
            .buttonStyle(.borderless)
            .font(.manrope(size: 20, weight: .medium))
            .disabled(apiKey.isEmpty)

            if let error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .frame(height: 80)
                    .padding(.top, 20)
            }
            Spacer(minLength: 56)
        }
        .font(.manrope(size: 16, weight: .medium))
        .background(Color.background.ignoresSafeArea())
        .onTapGesture {
            endEditing(force: true)
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
        AddApiKeyView(onValidateSuccess: {}, onSkip: {})
            .background(Color.background)
            .environment(\.colorScheme, .dark)
    }
}
