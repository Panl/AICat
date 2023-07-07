//
//  SettingsView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/21.
//

import SwiftUI
import Foundation
import ApphudSDK

struct SettingsView: View {
    var appVersion: String {
        Bundle.main.releaseVersion ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.buildNumber ?? "1"
    }

    let onClose: () -> Void

    @State var isPurcahsing = false
    @State var toast: Toast?
    @ObservedObject var store = DataStore

    var syncedText: LocalizedStringKey {
        if let syncedTime = store.lastSyncedTime {
            return LocalizedStringKey(Date(timeIntervalSince1970: Double(syncedTime)).toFormat())
        }
        return LocalizedStringKey("Not synchronized yet.")
    }

    var body: some View {
        NavigationView {
            List {
                Section("Developer") {
                    NavigationLink(destination: OpenAISettingsView()) {
                        Label("Custom API", systemImage: "hammer")
                            .labelStyle(.titleAndIcon)
                    }.tint(.primaryColor)
                    HStack {
                        Image(systemName: "arrow.clockwise.icloud")
                        Text("iCloud Sync")
                        Spacer()
                        if let error = store.syncError {
                            Button(action: {
                                toast = .init(type: .error, message: error.localizedDescription)
                            }, label: {
                                Image(systemName: "exclamationmark.icloud.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.red)
                            })
                        }
                        Text(syncedText)
                            .font(.manrope(size: 10, weight: .regular))
                            .opacity(0.4)
                    }
                }.tint(.primaryColor)
                Section("Donate") {
                    Button(action: { Task { await buyCatFood() } }) {
                        HStack {
                            Label("Buy me a can of cat food", systemImage: "fish")
                                .labelStyle(.titleAndIcon)
                            Spacer()
                            if isPurcahsing {
                                LoadingIndocator().frame(width: 20, height: 20)
                            }
                        }
                    }.tint(.primaryColor)
                }.tint(.primaryColor)
                Section("support") {
                    Link(destination: URL(string: "https://apps.apple.com/app/aicat-ultimate-ai-assistant/id6446479308?action=write-review")!) {
                        Label("Review on App Store", systemImage: "star")
                            .labelStyle(.titleAndIcon)
                    }

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
                    Link(destination: URL(string: "https://okjk.co/Cvz2JY")!){
                        Label("潘磊Rego", image: "jike-logo")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://twitter.com/panlei106")!){
                        Label("Rego", image: "twitter_circled")
                            .labelStyle(.titleAndIcon)
                    }
                    Link(destination: URL(string: "https://www.producthunt.com/products/aicat-ai-assistant-powered-by-chatgpt#aicat-ai-assistant-powered-by-chatgpt")!){
                        Label("Upvote on Product Hunt", image: "product-hunt-logo")
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
            .frame(minWidth: 300)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    }
                    .tint(.primaryColor)
                }
                #endif
            }
        }
        .background(Color.background)
        .font(.manrope(size: 16, weight: .medium))
        .toast($toast)
    }

    func buyCatFood() async {
        if Apphud.isSandbox() {
            toast = Toast(type: .info, message: "😿 Please use the App Store version for donations.")
            return
        }
        guard !isPurcahsing else { return }
        isPurcahsing = true
        let payWall = await Apphud.paywalls().first
        if let catFood = payWall?.products.first(where: { $0.productId == catFoodId }) {
            let result = await Apphud.purchase(catFood)
            if let error = result.error {
                toast = Toast(type: .error, message: "Buy food failed! 😿 \(error)")
            } else {
                toast = Toast(type: .success, message: "Thank you for your food 😻")
            }
        } else {
            toast = Toast(type: .error, message: "Buy food failed! 😿 (nil)")
        }
        isPurcahsing = false
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(onClose: {})
            .environment(\.colorScheme, .light)
    }
}
