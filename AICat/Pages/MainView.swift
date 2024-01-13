//
//  MainView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/24.
//

import SwiftUI
import Blackbird
import Combine
import Perception

@Perceptible
class ChatStateViewModel {

    var chatListStore = ChatListViewModel()
    var conversationStore = ConversationViewModel()
    var mainChat: Conversation = mainConversation
    var conversations: [Conversation] = []

    var allConversations: [Conversation] {
        [mainChat] + conversations
    }

    func fetchConversations() {
        Task {
            let (mainChat, conversations) = await queryConversations()
            updateConversations(mainChat, conversations: conversations)
        }
    }

    private func updateConversations(_ mainChat: Conversation, conversations: [Conversation]) {
        let all = [mainChat] + conversations
        self.mainChat = mainChat
        self.conversations = conversations
        self.chatListStore.chats = all
        self.conversationStore.prompts = conversations
        let selected = all.first(where: { $0.id == UserDefaults.currentChatId }) ?? mainChat
        self.chatListStore.selectedChat = selected
        self.conversationStore.conversation = selected
    }

    func addChat(_ chat: Conversation) {
        UserDefaults.currentChatId = chat.id
        self.conversations.insert(chat, at: 0)
        self.chatListStore.chats = allConversations
        self.conversationStore.prompts = conversations
        self.chatListStore.selectedChat = chat
        self.conversationStore.conversation = chat
    }

    func updateChat(_ chat: Conversation) {
        if chat.id == mainChat.id {
            mainChat = chat
        } else if let index = conversations.firstIndex(where: { $0.id == chat.id }) {
            conversations[index] = chat
        }
        chatListStore.selectedChat = chat
        chatListStore.chats = allConversations
        conversationStore.prompts = conversations
        conversationStore.conversation = chat
        Task {
            await saveConversation(chat)
        }
    }

    func selectChat(_ chat: Conversation) {
        UserDefaults.currentChatId = chat.id
        chatListStore.selectedChat = chat
        conversationStore.conversation = chat
    }

    func saveChat(_ chat: Conversation) {
        Task {
            await saveConversation(chat)
            addChat(chat)
            selectChat(chat)
        }
    }

    func clearChats(_ chats: [Conversation]) {
        Task {
            await clearConversations(chats)
            let removeIds = chats.map(\.id)
            let newChats = conversations.filter { !removeIds.contains($0.id) }
            updateConversations(mainChat, conversations: newChats)
        }
    }

    func deleteChat(_ chat: Conversation) {
        Task {
            await deleteConversation(chat)
            let newChats = conversations.filter { $0.id != chat.id }
            return updateConversations(mainChat, conversations: newChats)
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
        await DataStore.saveAndSync(conversation)
    }

    func deleteConversation(_ conversation: Conversation) async {
        var c = conversation
        c.timeRemoved = Date.now.timeInSecond
        await DataStore.saveAndSync(c)
    }

    func clearConversations(_ conversations: [Conversation]) async {
        let conversationsToDelete = conversations.map { item in
            var c = item
            c.timeRemoved = Date.now.timeInSecond
            return c
        }
        await DataStore.saveAndSync(items: conversationsToDelete)
    }
}

struct MainView: View {

    @State private var cancelable: AnyCancellable?
    let chatState = ChatStateViewModel()

    var body: some View {
        WithPerceptionTracking {
            GeometryReader { proxy in
                if proxy.size.width > 560 {
                    SplitView(size: proxy.size)
                } else {
                    CompactView()
                }
            }
            .environment(chatState)
            .tint(Color.primaryColor)
            .onAppear {
                #if os(iOS)
                cancelable = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    .sink { _ in
                        print("App will enter foreground")
                        DataStore.sync(complete: nil)
                    }
                #elseif os(macOS)
                cancelable = NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)
                    .sink { _ in
                        print("App will enter foreground")
                        DataStore.sync(complete: nil)
                    }
                #endif
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
