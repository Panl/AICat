//
//  MainView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/24.
//

import SwiftUI
import Blackbird
import ComposableArchitecture

struct AppReducer: ReducerProtocol {

    @AppStorage("currentChat.id") var chatId: String?

    struct State: Equatable {
        var conversationList = ConversationListReducer.State()
        var conversationMessages = ConversationFeature.State()
        var mainChat: Conversation = mainConversation
        var conversations: [Conversation] = []

        var allConversations: [Conversation] {
            [mainChat] + conversations
        }
    }

    enum Action {
        case queryConversations
        case addChat(Conversation)
        case selectChat(Conversation)
        case updateConversations((Conversation, [Conversation]))
        case conversationMessagesAction(ConversationFeature.Action)
        case conversationListAction(ConversationListReducer.Action)
    }

    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .queryConversations:
                return .task {
                    let result = await queryConversations()
                    return .updateConversations(result)
                }
            case .addChat(let chat):
                state.conversations.insert(chat, at: 0)
                state.conversationList.conversations = state.allConversations
                state.conversationMessages.prompts = state.conversations
                state.conversationList.selectedChat = chat
                state.conversationMessages.conversation = chat
                return .run { _ in
                    chatId = chat.id
                }
            case .selectChat(let chat):
                chatId = chat.id
                state.conversationList.selectedChat = chat
                state.conversationMessages.conversation = chat
                return .none
            case .updateConversations(let (mainChat, conversations)):
                let all = [mainChat] + conversations
                state.mainChat = mainChat
                state.conversations = conversations
                state.conversationList.conversations = all
                state.conversationMessages.prompts = conversations
                let selected = all.first(where: { $0.id == chatId }) ?? mainChat
                state.conversationList.selectedChat = selected
                state.conversationMessages.conversation = selected
                return .none
            case .conversationMessagesAction(let action):
                switch action {
                case .updateConversation(let chat):
                    if chat.id == state.mainChat.id {
                        state.mainChat = chat
                    } else if let index = state.conversations.firstIndex(where: { $0.id == chat.id }) {
                        state.conversations[index] = chat
                    }
                    state.conversationList.selectedChat = chat
                    state.conversationList.conversations = state.allConversations
                    state.conversationMessages.prompts = state.conversations
                    state.conversationMessages.conversation = chat
                    return .run { _ in
                        await saveConversation(chat)
                    }
                default:
                    return .none
                }
            case .conversationListAction(let action):
                switch action {
                case .deleteConversation(let chat):
                    return .task { [chats = state.conversations, main = state.mainChat] in
                        await deleteConversation(chat)
                        let newChats = chats.filter { $0.id != chat.id }
                        return .updateConversations((main, newChats))
                    }
                case .clearConversations(let chats):
                    return .task { [conversations = state.conversations, main = state.mainChat ] in
                        await clearConversations(chats)
                        let removeIds = chats.map(\.id)
                        let newChats = conversations.filter { !removeIds.contains($0.id) }
                        return .updateConversations((main, newChats))
                    }
                case .saveConversation(let chat):
                    return .run { send in
                        await saveConversation(chat)
                        await send(.addChat(chat))
                        await send(.selectChat(chat))
                    }
                default:
                    return .none
                }
            }
        }
        Scope(state: \.conversationList, action: /Action.conversationListAction) {
            ConversationListReducer()
        }
        Scope(state: \.conversationMessages, action: /Action.conversationMessagesAction) {
            ConversationFeature()
        }
    }

    func queryMainConversation() async -> Conversation {
        if let dbMain = try! await Conversation.read(from: db, id: mainConversation.id) {
            return dbMain
        } else {
            await saveConversation(mainConversation)
            return mainConversation
        }
    }

    func queryConversations() async -> (Conversation, [Conversation]) {
        let mainChat = await queryMainConversation()
        let chats = try! await Conversation.read(from: db, matching: \.$timeRemoved == 0 && \.$id != mainConversation.id, orderBy: .descending(\.$timeCreated))
        return (mainChat, chats)
    }

    func saveConversation(_ conversation: Conversation) async {
        await db.upsert(model: conversation)
    }

    func deleteConversation(_ conversation: Conversation) async {
        var c = conversation
        c.timeRemoved = Date.now.timeInSecond
        await saveConversation(c)
    }

    func clearConversations(_ conversations: [Conversation]) async {
        for var c in conversations {
            c.timeRemoved = Date.now.timeInSecond
            await saveConversation(c)
        }
    }
}

struct MainView: View {

    @StateObject var appStateVM = AICatStateViewModel()

    let store = Store(initialState: AppReducer.State(), reducer: AppReducer())

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > 560 {
                SplitView(size: proxy.size, store: store)
            } else {
                CompactView(store: store)
            }
        }.environmentObject(appStateVM)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
