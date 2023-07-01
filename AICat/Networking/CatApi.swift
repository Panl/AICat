//
//  CatApi.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Foundation
import OpenAI
import Combine

enum CatApi {

    private(set) static var currentStreamOpenAI: OpenAI?

    static var apiClient: OpenAI {
        let apiKey = UserDefaults.openApiKey ?? openAIKey
        let apiHost = UserDefaults.apiHost.replacingOccurrences(of: "https://", with: "")
        let configratuion = OpenAI.Configuration(
            token: apiKey,
            host: apiHost,
            timeoutInterval: 60
        )
        return OpenAI(configuration: configratuion, session: URLSession.shared)
    }

    static func cancelStreamChat() {
        currentStreamOpenAI?.cancelAllStreamingRequests()
    }

    static func cancelTaskWithUrl(_ url: URL?) {
        URLSession.shared.getAllTasks { tasks in
            tasks
                .filter { $0.state == .running }
                .filter { $0.originalRequest?.url == url }.first?
                .cancel()
        }
    }

    static func complete(apiHost: String? = nil, apiKey: String? = nil, messages: [Chat]) async throws -> ChatResult {
        let host = apiHost ?? UserDefaults.customApiHost
        let key = apiKey ?? UserDefaults.openApiKey ?? ""
        let configratuion = OpenAI.Configuration(
            token: key,
            host: host.replacingOccurrences(of: "https://", with: ""),
            timeoutInterval: 60
        )
        let client = OpenAI(configuration: configratuion, session: URLSession.shared)
        let query = ChatQuery(
            model: "gpt-3.5-turbo",
            messages: messages,
            temperature: 0.7,
            topP: 1,
            presencePenalty: 0,
            frequencyPenalty: 0,
            stream: false
        )
        return try await client.chats(query: query)
    }

    static func validate(apiHost: String, apiKey: String) async throws -> ChatResult {
        try await complete(apiHost: apiHost, apiKey: apiKey, messages: [Chat(role: .user, content: "say this is a test")])
    }

    static func listGPTModels() async throws -> [Model] {
        let result = try await apiClient.models()
        let gptModels = result.data.map({ $0.id }).filter({ $0.contains("gpt") })
        return gptModels.sorted()
    }

    static func streamChat(messages: [Chat], conversation: Conversation) async -> AsyncThrowingStream<ChatStreamResult, Error> {
        var messageToSend = messages
        let prompt = conversation.prompt
        if !prompt.isEmpty {
            let system = Chat(role: .system, content: prompt)
            messageToSend = [system] + messages
        }
        let query = ChatQuery(
            model: conversation.model,
            messages: messageToSend,
            temperature: conversation.temperature,
            topP: conversation.topP,
            presencePenalty: conversation.presencePenalty,
            frequencyPenalty: conversation.frequencyPenalty,
            stream: true
        )
        currentStreamOpenAI = apiClient
        return currentStreamOpenAI!.chatsStream(query: query)
    }
}

extension Chat.Role {
    init(name: String) {
        switch name {
        case "system":
            self = .system
        case "user":
            self = .user
        case "assistant":
            self = .assistant
        case "function":
            self = .function
        default:
            self = .system
        }
    }
}
