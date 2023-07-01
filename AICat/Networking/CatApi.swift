//
//  CatApi.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Foundation
import OpenAI
import Combine

struct StreamResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]

    struct Choice: Codable {
        let delta: Delta
        let finishReason: String?
    }

    struct Delta: Codable {
        let role: String?
        let content: String?
    }
}

enum CatApi {

    static var chatCompletionUrl: String {
        "\(UserDefaults.apiHost)/v1/chat/completions"
    }

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

    static func cancelMessageStream() {
        cancelTaskWithUrl(URL(string: chatCompletionUrl))
    }

    static func cancelTaskWithUrl(_ url: URL?) {
        URLSession.shared.getAllTasks { tasks in
            tasks
                .filter { $0.state == .running }
                .filter { $0.originalRequest?.url == url }.first?
                .cancel()
        }
    }

    static func decodeResponse(data: Data) -> StreamResponse? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let response = try decoder.decode(StreamResponse.self, from: data)
            return response
        } catch {
            print("decode error: \(error) - rawJson: \(String(decoding: data, as: UTF8.self))")
        }
        return nil
    }

    static func complete(apiHost: String? = nil, apiKey: String? = nil, messages: [Message]) async throws -> ChatResult {
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
            messages: messages.map({ Chat(role: .init(name: $0.role), content: $0.content)}),
            temperature: 0.7,
            topP: 1,
            presencePenalty: 0,
            frequencyPenalty: 0,
            stream: false
        )
        return try await client.chats(query: query)
    }

    static func validate(apiKey: String) async throws -> ChatResult {
        try await complete(apiKey: apiKey, messages: [Message(role: "user", content: "say this is a test")])
    }

    static func validate(apiHost: String, apiKey: String) async throws -> ChatResult {
        try await complete(apiHost: apiHost, apiKey: apiKey, messages: [Message(role: "user", content: "say this is a test")])
    }

    static func listGPTModels() async throws -> [Model] {
        let result = try await apiClient.models()
        let gptModels = result.data.map({ $0.id }).filter({ $0.contains("gpt") })
        return gptModels.sorted()
    }

    static func streamChat(messages: [Message], conversation: Conversation) async -> AsyncThrowingStream<ChatStreamResult, Error> {
        var messageToSend = messages
        let prompt = conversation.prompt
        if !prompt.isEmpty {
            let system = Message(role: "system", content: prompt)
            messageToSend = [system] + messages
        }
        let query = ChatQuery(
            model: conversation.model,
            messages: messageToSend.map({ Chat(role: .init(name: $0.role), content: $0.content)}),
            temperature: conversation.temperature,
            topP: conversation.topP,
            presencePenalty: conversation.presencePenalty,
            frequencyPenalty: conversation.frequencyPenalty,
            stream: true
        )
        return apiClient.chatsStream(query: query)
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

struct Message: Codable {
    let role: String
    let content: String
}
