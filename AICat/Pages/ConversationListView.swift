//
//  ConversationListView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import SwiftUI
import ComposableArchitecture

struct ConversationListReducer: ReducerProtocol {
    struct State: Equatable {
        var selectedChat: Conversation = mainConversation
        var conversations: [Conversation] = []
        var showClearAllChatsAlert = false
        var showSettingsView = false
        var showAddAPIKeyView = false
        var showPremiumPage = false
    }

    enum Action {
        case toggleShowClearAllChats(Bool)
        case toggleShowSettings(Bool)
        case toggleShowAddAPIKey(Bool)
        case toggleShowPremiumPage(Bool)
        case deleteConversation(Conversation)
        case clearConversations([Conversation])
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .toggleShowAddAPIKey(let show):
            state.showAddAPIKeyView = show
            return .none
        case .toggleShowSettings(let show):
            state.showSettingsView = show
            return .none
        case .toggleShowPremiumPage(let show):
            state.showPremiumPage = show
            return .none
        case .toggleShowClearAllChats(let show):
            state.showClearAllChatsAlert = show
            return .none
        case .deleteConversation, .clearConversations:
            return .none
        }
    }
}

struct ConversationListView: View {
    let onAddChat: () -> Void
    let onChatChanged: (Conversation) -> Void

    @EnvironmentObject var appStateVM: AICatStateViewModel
    let store: StoreOf<ConversationListReducer>
    
    var premiumText: String {
        if appStateVM.isPremium {
            return "AICat Premium"
        } else {
            return "AICat Premium(\(appStateVM.sentMessageCount)/\(appStateVM.freeMessageCount))"
        }
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                Image(systemName: "timelapse")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .padding(.top, 32)
                Spacer().frame(height: 32)
                HStack {
                    Text("CONVERSATIONS")
                        .font(.manrope(size: 14, weight: .semibold))
                        .foregroundColor(.blackText.opacity(0.4))
                    Spacer()
                }.padding(.leading, 20)
                ScrollView(showsIndicators: false) {
                    LazyVStack {
                        Spacer().frame(height: 10)
                        Button(action: onAddChat) {
                            HStack {
                                Image(systemName: "plus.bubble")
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20)
                                Text("New Chat")
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.borderless)
                        .padding(.horizontal, 8)
                        .tint(.blackText.opacity(0.5))
                        ForEach(viewStore.conversations) { conversation in
                            Button(action: { onChatChanged(conversation) }) {
                                HStack {
                                    Image(systemName: conversation.isMain ? "command" : "bubble.left" )
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20)
                                    Text(conversation.title)
                                        .lineLimit(1)
                                        .font(.manrope(size: 16, weight: conversation == viewStore.selectedChat ? .semibold : .medium))
                                        .foregroundColor(conversation == viewStore.selectedChat ? .blackText : .blackText.opacity(0.7))
                                    Spacer()
                                    if viewStore.selectedChat == conversation {
                                        Circle()
                                            .frame(width: 10, height: 10)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.primaryColor.opacity(0.8), .primaryColor.opacity(0.5)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing)
                                            )
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                            .buttonStyle(.borderless)
                            .tint(conversation == viewStore.selectedChat ? .primaryColor : .primaryColor.opacity(0.7))
                            .contextMenu {
                                if !conversation.isMain {
                                    Button(role: .destructive, action: { viewStore.send(.deleteConversation(conversation)) }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .padding(.horizontal, 8)

                        }
                    }
                }
                RoundedRectangle(cornerRadius: 0.5)
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
                VStack(spacing: 0) {
                    Button(action: { viewStore.send(.toggleShowClearAllChats(true)) }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Conversations")
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderless)
                    .tint(.blackText.opacity(0.5))
                    .padding(.horizontal, 20)
                    .alert("Are you sure to clear all conversations", isPresented: viewStore.binding(get: \.showClearAllChatsAlert, send: ConversationListReducer.Action.toggleShowClearAllChats)) {
                        Button("Sure", role: .destructive) {
                            let conversations = viewStore.conversations.filter { !$0.isMain }
                            viewStore.send(.clearConversations(conversations))
                        }
                        Button("Cancel", role: .cancel) {
                            viewStore.send(.toggleShowClearAllChats(false))
                        }
                    }
                    if appStateVM.developMode {
                        Button(action: { viewStore.send(.toggleShowAddAPIKey(true)) }) {
                            HStack {
                                Image(systemName: "key.viewfinder")
                                Text("OpenAI API Key")
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderless)
                        .tint(.blackText.opacity(0.5))
                        .padding(.horizontal, 20)
                    }
                    Button(action: {
                        #if os(iOS)
                        UIApplication.shared.open(URL(string: "https://help.openai.com/en/collections/3742473-chatgpt")!)
                        #elseif os(macOS)
                        NSWorkspace.shared.open(URL(string: "https://help.openai.com/en/collections/3742473-chatgpt")!)
                        #endif
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("Updates & FAQ")
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 20)
                    .tint(.blackText.opacity(0.5))
                    if !appStateVM.developMode {
                        Button(
                            action: { viewStore.send(.toggleShowPremiumPage(true)) }
                        ) {
                            HStack {
                                Image(systemName: "crown")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                Text(LocalizedStringKey(premiumText))
                                Spacer()
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderless)
                        .padding(.horizontal, 20)
                        .tint(.blackText.opacity(0.5))
                    }
                    #if os(iOS)
                    Button(action: { viewStore.send(.toggleShowSettings(true)) }) {
                        HStack {
                            Image(systemName: "gearshape")
                            Text("Settings")
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 20)
                    .tint(.blackText.opacity(0.5))
                    .fullScreenCover(isPresented: viewStore.binding(get: \.showSettingsView, send: ConversationListReducer.Action.toggleShowSettings)) {
                        SettingsView {
                            viewStore.send(.toggleShowSettings(false))
                        }
                    }
                    #endif
                }
                Spacer().frame(height: 16)
            }
            .ignoresSafeArea(.keyboard)
            .font(.manrope(size: 16, weight: .medium))
            .sheet(isPresented: viewStore.binding(get: \.showAddAPIKeyView, send: ConversationListReducer.Action.toggleShowAddAPIKey)) {
                AddApiKeyView(
                    onValidateSuccess: { viewStore.send(.toggleShowAddAPIKey(false)) },
                    onSkip: { viewStore.send(.toggleShowAddAPIKey(false)) }
                )
            }
            .sheet(isPresented: viewStore.binding(get: \.showPremiumPage, send: ConversationListReducer.Action.toggleShowPremiumPage)) {
                PremiumPage(showPremium: viewStore.binding(get: \.showPremiumPage, send: ConversationListReducer.Action.toggleShowPremiumPage))
            }
        }
    }
}

struct ConversationListView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationListView(
            onAddChat: {}, onChatChanged: { _ in }, store: Store(initialState: ConversationListReducer.State(), reducer: ConversationListReducer())
        ).environmentObject(AICatStateViewModel())
    }
}
