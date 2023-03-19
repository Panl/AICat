//
//  CatApi.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import Alamofire

enum CatApi {

    static var apiKey = "your OpenAI Apikey"

    static func complete(content: String) async -> Result<CompleteResponse, AFError>{
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        return await AF.request(
            "https://api.openai.com/v1/chat/completions",
            method: .post,
            parameters: CompleteParams(
                model: "gpt-3.5-turbo",
                messages: [Message(role: "user", content: content)]
            ),
            encoder: .json,
            headers: headers
        )
        .serializingDecodable(CompleteResponse.self)
        .response
        .result
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
