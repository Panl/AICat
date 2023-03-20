//
//  CatApi.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Foundation
import Alamofire

enum CatApi {
    static func complete(apiKey: String? = nil, messages: [Message]) async -> Result<CompleteResponse, AFError> {
        let key = apiKey ?? UserDefaults.openApiKey
        guard let key else {
            return .failure(AFError.createURLRequestFailed(error: NSError(domain: "missing OpenAI API key", code: -1)))
        }
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(key)"
        ]
        return await AF.request(
            "https://api.openai.com/v1/chat/completions",
            method: .post,
            parameters: CompleteParams(
                model: "gpt-3.5-turbo",
                messages: messages
            ),
            encoder: .json,
            headers: headers,
            requestModifier: { request in
                request.timeoutInterval = 30
            }
        )
        .logRequest()
        .serializingDecodable(CompleteResponse.self)
        .response
        .logResponse()
        .result
    }

    static func complete(messages: [Message], with prompt: String) async -> Result<CompleteResponse, AFError> {
        let system = Message(role: "system", content: prompt)
        return await complete(messages: [system] + messages)
    }

    static func validate(apiKey: String) async -> Result<CompleteResponse, AFError> {
        await complete(apiKey: apiKey, messages: [Message(role: "user", content: "say this is a test")])
    }
}

extension Request {
    func logRequest() -> Self {
        #if DEBUG
        cURLDescription { curl in
            debugPrint("====Request Start====")
            debugPrint(curl)
            debugPrint("====Request End====")
        }
        #endif
        return self
    }
}

extension DataResponse {
    func logResponse() -> Self {
        #if DEBUG
        debugPrint("====Response Start====")
        switch result {
        case .success(let data):
            debugPrint(data)
        case .failure(let error):
            debugPrint(error)
        }
        debugPrint("====Response End====")
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
