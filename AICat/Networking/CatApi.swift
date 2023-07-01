//
//  CatApi.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Foundation
import Alamofire
import OpenAI

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

    static func completeMessageStream(apiKey: String? = nil, messages: [Message], conversation: Conversation) async throws -> AsyncThrowingStream<(String, StreamResponse.Delta), Error> {
        let key = apiKey ?? UserDefaults.openApiKey ?? openAIKey
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(key)"
        ]
        var messageToSend = messages
        let prompt = conversation.prompt
        if !prompt.isEmpty {
            let system = Message(role: "system", content: prompt)
            messageToSend = [system] + messages
        }
        var request = try URLRequest(url: "\(UserDefaults.apiHost)/v1/chat/completions", method: .post, headers: headers)
        let body = CompleteParams(
            model: conversation.model,
            messages: messageToSend,
            temperature: conversation.temperature,
            stream: true,
            topP: conversation.topP,
            frequencyPenalty: conversation.frequencyPenalty,
            presencePenalty: conversation.presencePenalty
        )
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 60
        #if DEBUG
        print("=====request=====")
        print(body)
        print("======")
        #endif
        let (result, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NSError(domain: "Invalid response", code: 0) }
        guard 200...299 ~= httpResponse.statusCode else {
            var errorText = ""
            for try await line in result.lines {
                errorText += line
            }
            throw NSError(domain: "Bad response: \(httpResponse.statusCode), \(errorText)", code: 0)
        }
        return AsyncThrowingStream<(String, StreamResponse.Delta), Error> { continuation in
            Task {
                do {
                    for try await line in result.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = decodeResponse(data: data),
                           let delta = response.choices.first?.delta {
                            let model = response.model
                            continuation.yield((model, delta))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    static func cancelMessageStream() {
        cancelTaskWithUrl(URL(string: "\(UserDefaults.apiHost)/v1/chat/completions"))
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

    static func complete(apiHost: String? = nil, apiKey: String? = nil, messages: [Message]) async -> Result<CompleteResponse, AFError> {
        let host = apiHost ?? UserDefaults.customApiHost
        let key = apiKey ?? UserDefaults.openApiKey ?? ""
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(key)"
        ]
        return await AF.request(
            "\(host)/v1/chat/completions",
            method: .post,
            parameters: CompleteParams(
                model: "gpt-3.5-turbo",
                messages: messages,
                temperature: 0.7,
                stream: false,
                topP: 1,
                frequencyPenalty: 0,
                presencePenalty: 0
            ),
            encoder: .json,
            headers: headers,
            requestModifier: { request in
                request.timeoutInterval = 60
            }
        )
        .validate(statusCode: 200..<300)
        .logRequest()
        .serializingDecodable(CompleteResponse.self)
        .response
        .logResponse()
        .result
    }

    static func validate(apiKey: String) async -> Result<CompleteResponse, AFError> {
        await complete(apiKey: apiKey, messages: [Message(role: "user", content: "say this is a test")])
    }

    static func validate(apiHost: String, apiKey: String) async -> Result<CompleteResponse, AFError> {
        await complete(apiHost: apiHost, apiKey: apiKey, messages: [Message(role: "user", content: "say this is a test")])
    }

    static func listGPTModels() async throws -> [Model] {
        let apiKey = UserDefaults.openApiKey ?? openAIKey
        let apiClient = OpenAI(apiToken: apiKey)
        let result = try await apiClient.models()
        let gptModels = result.data.map({ $0.id }).filter({ $0.contains("gpt") })
        return gptModels.sorted()
    }
}

extension Request {
    func logRequest() -> Self {
        #if DEBUG
        cURLDescription { curl in
            print("====Request Start====")
            print(curl)
            print("====Request End====")
        }
        #endif
        return self
    }
}

extension DataResponse {
    func logResponse() -> Self {
        #if DEBUG
        print("====Response Start====")
        switch result {
        case .success(let data):
            print(data)
        case .failure(let error):
            print(error)
        }
        print("====Response End====")
        #endif
        return self
    }
}

struct Message: Codable {
    let role: String
    let content: String
}

struct CompleteParams: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let stream: Bool
    let topP: Double
    let frequencyPenalty: Double
    let presencePenalty: Double

    enum CodingKeys: String, CodingKey {
        case model = "model"
        case messages = "messages"
        case temperature = "temperature"
        case stream = "stream"
        case topP = "top_p"
        case frequencyPenalty = "frequency_penalty"
        case presencePenalty = "presence_penalty"
    }
}

struct CompleteResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let choices: [Choice]
    let usage: Usage
}

struct Choice: Codable {
    let index: Int
    let message: Message
    let finishReason: String

    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }

}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}
