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
                Section("support") {
                    Button(action: {}) {
                        Label("Share AICat", systemImage: "square.and.arrow.up")
                            .labelStyle(.titleAndIcon)
                    }.tint(.black)
                    Button(action: {}) {
                        Label("Contact Us", systemImage: "envelope")
                            .labelStyle(.titleAndIcon)
                    }.tint(.black)
                    Button(action: {}) {
                        Label("Privacy and Policy", systemImage: "person.badge.shield.checkmark")
                            .labelStyle(.titleAndIcon)
                    }.tint(.black)
                }
            }
            .font(.custom("Avenir Next", size: 16))
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
