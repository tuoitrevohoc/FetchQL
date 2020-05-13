//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation

struct AppSyncClientMessage<Variable: Encodable> {
    let message: ClientMessage<Variable>
    let authorization: [String: String?]
}

extension AppSyncClientMessage: Encodable {
    
    enum CodingKeys: CodingKey {
        case type
        case id
        case payload
    }
    
    enum PayLoadCondingKeys: CodingKey {
        case data
        case extensions
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch message {
        case .connectionInit:
            try container.encode(ClientMessageType.connectionInit.rawValue, forKey: .type)
        case .start(let id, let query, let variables):
            try container.encode(ClientMessageType.start.rawValue, forKey: .type)
            try container.encode(id, forKey: .id)
            var payloadContainer = container.nestedContainer(keyedBy: PayLoadCondingKeys.self, forKey: .payload)
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(QueryPayload(query: query, variables: variables, operationName: nil))
            let dataString = String(data: data, encoding: .utf8)
            
            try payloadContainer.encode(dataString, forKey: .data)
            try payloadContainer.encode(
                [
                    "authorization": authorization
                ],
                forKey: .extensions
            )
        case .stop(let id):
            try container.encode(ClientMessageType.stop.rawValue, forKey: .type)
            try container.encode(id, forKey: .id)
        case .connectionTerminate:
            try container.encode(ClientMessageType.connectionTerminate.rawValue, forKey: .type)
        }
    }
}

/// The message coder
struct AppSyncCoder: MessageCoder {
    
    /// the endPoint
    let endPoint: URL
    
    /// let apiKey
    let apiKey: String
    
    /// Create an AppSync Coder
    ///
    /// - Parameters:
    ///   - endPoint: the endpoint
    ///   - apiKey: apiKey
    init(endPoint: URL, apiKey: String) {
        self.endPoint = endPoint
        self.apiKey = apiKey
    }
    
    /// Encode
    /// - Parameter message: the message description
    /// - Returns: description
    func encode<Variable>(message: ClientMessage<Variable>) throws -> String where Variable : Encodable {
        
        let encoder = JSONEncoder()
        let authorization = [
            "host": endPoint.host,
            "x-api-key": apiKey,
            "x-amz-user-agent": "aws-amplify/3.2.5 js",
            "x-amz-date": "\(Date().amzDate)"
        ]
        
        let appSyncMessage = AppSyncClientMessage(message: message, authorization: authorization)
        let data = try encoder.encode(appSyncMessage)
        let result = String(data: data, encoding: .utf8)!
        
        print(result)
        return result
    }
}

extension Date {
    fileprivate var amzDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let value = formatter.string(from: self)
        return value.replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: ":", with: "")
    }
}
