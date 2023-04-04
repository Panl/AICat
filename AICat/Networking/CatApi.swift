//
//  CatApi.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Foundation
import Alamofire

//{
//    "id": "chatcmpl-6yCEXASoUbnpxciRDjFSBdVCtVv7d",
//    "object": "chat.completion.chunk",
//    "created": 1679804725,
//    "model": "gpt-3.5-turbo-0301",
//    "choices": [{
//        "delta": {
//            "content": "As"
//        },
//        "index": 0,
//        "finish_reason": null
//    }]
//}

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

    static func completeMessageStream(apiKey: String? = nil, messages: [Message], with prompt: String? = nil) async throws -> AsyncThrowingStream<StreamResponse.Delta, Error> {
        let key = apiKey ?? UserDefaults.openApiKey
        guard let key else { throw NSError(domain: "missing OpenAI API key", code: -1) }
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(key)"
        ]
        let temperature = UserDefaults.temperature
        let model = UserDefaults.model
        var messageToSend = messages
        if let prompt, !prompt.isEmpty {
            let system = Message(role: "system", content: prompt)
            messageToSend = [system] + messages
        }
        var request = try URLRequest(url: "https://api.openai.com/v1/chat/completions", method: .post, headers: headers)
        let body = CompleteParams(
            model: model,
            messages: messageToSend,
            temperature: temperature,
            stream: true
        )
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 60
        print("=====request=====")
        print(body)
        print("======")
        let (result, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NSError(domain: "Invalid response", code: 0) }
        guard 200...299 ~= httpResponse.statusCode else {
            var errorText = ""
            for try await line in result.lines {
                errorText += line
            }
            throw NSError(domain: "Bad response: \(httpResponse.statusCode), \(errorText)", code: 0)
        }
        return AsyncThrowingStream<StreamResponse.Delta, Error> { continuation in
            Task {
                do {
                    for try await line in result.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = decodeResponse(data: data),
                           let delta = response.choices.first?.delta {
                            continuation.yield(delta)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
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

    static func decode(data: Data) -> StreamResponse? {
        let str = String(decoding: data, as: UTF8.self)
        if str.hasPrefix("data: ") {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let validData = str.dropFirst(6).data(using: .utf8)
                let response = try decoder.decode(StreamResponse.self, from: validData!)
                return response
            } catch {
                print("decode error: \(error) - rawJson: \(str)")
            }
        }
        return nil
    }

    static func complete(apiKey: String? = nil, messages: [Message]) async -> Result<CompleteResponse, AFError> {
        let key = apiKey ?? UserDefaults.openApiKey
        guard let key else {
            return .failure(AFError.createURLRequestFailed(error: NSError(domain: "missing OpenAI API key", code: -1)))
        }
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(key)"
        ]
        let temperature = UserDefaults.temperature
        let model = UserDefaults.model
        return await AF.request(
            "https://api.openai.com/v1/chat/completions",
            method: .post,
            parameters: CompleteParams(
                model: model,
                messages: messages,
                temperature: temperature,
                stream: false
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

    static func complete(messages: [Message], with prompt: String) async -> Result<CompleteResponse, AFError> {
        if prompt.isEmpty {
            return await complete(messages: messages)
        } else {
            let system = Message(role: "system", content: prompt)
            return await complete(messages: [system] + messages)
        }
    }

    static func validate(apiKey: String) async -> Result<CompleteResponse, AFError> {
        await complete(apiKey: apiKey, messages: [Message(role: "user", content: "say this is a test")])
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
