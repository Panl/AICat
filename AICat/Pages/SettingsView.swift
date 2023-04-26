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
    var appVersion: String {
        Bundle.main.releaseVersion ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.buildNumber ?? "1"
    }

    let onClose: () -> Void

    var body: some View {
        NavigationView {
            List {
                Section("Developer") {
                    NavigationLink(destination: OpenAISettingsView()) {
                        Label("Custom API", systemImage: "hammer")
                            .labelStyle(.titleAndIcon)
                    }.tint(.primaryColor)
                }.tint(.primaryColor)
                Section("support") {
                    Link(destination: URL(string: "https://learnprompting.org/")!) {
                        Label("Learn Prompting", systemImage: "book")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://github.com/f/awesome-chatgpt-prompts")!) {
                        Label("Awesome prompts", systemImage: "square.stack.3d.up")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "mailto:iplay.coder@gmail.com")!){
                        Label("Contact Us", systemImage: "envelope.open")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://epochpro.app/aicat_privacy")!) {
                        Label("Privacy Policy", systemImage: "lock.rectangle.on.rectangle")
                            .labelStyle(.titleAndIcon)
                    }
                }.tint(.primaryColor)
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
                }.tint(.primaryColor)
                Section("Source Code") {
                    Link(destination: URL(string: "https://github.com/Panl/AICat.git")!){
                        Label("AICat.git", image: "github_icon")
                            .labelStyle(.titleAndIcon)
                    }
                }.tint(.primaryColor)
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
                        }.tint(.primaryColor)
                    }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    }
                    .tint(.primaryColor)
                }
            }
        }
        .background(Color.background)
        .font(.manrope(size: 16, weight: .medium))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(onClose: {})
            .environment(\.colorScheme, .light)
    }
}
