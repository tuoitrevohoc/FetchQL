//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation

struct QueryPayload<Variable: Encodable>: Encodable {
    let query: String
    let variables: Variable
    let operationName: String?
}

enum ClientMessageType: String {
    case connectionInit = "connection_init"
    case start = "start"
    case stop = "stop"
    case connectionTerminate = "connection_terminate"
}

/// the client message type - message from client
public enum ClientMessage<Variable: Encodable> {
    case connectionInit
    case start(id: String, query: String, variables: Variable)
    case stop(id: String)
    case connectionTerminate
}

// because swift doesn't support default generic parameter yet
// uses this as a workaround
typealias ClientMessages = ClientMessage<Bool?>

// codable implementation for client message
extension ClientMessage: Encodable {
    
    enum CodingKeys: CodingKey {
        case type
        case id
        case payload
    }
    
    /// Encoding
    /// - Parameter encoder: encoder
    /// - Throws: error when parsing
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .connectionInit:
            try container.encode(ClientMessageType.connectionInit.rawValue, forKey: .type)
        case .start(let id, let query, let variables):
            try container.encode(ClientMessageType.start.rawValue, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(
                QueryPayload(query: query, variables: variables, operationName: nil),
                forKey: .payload
            )
        case .stop(let id):
            try container.encode(ClientMessageType.stop.rawValue, forKey: .type)
            try container.encode(id, forKey: .id)
        case .connectionTerminate:
            try container.encode(ClientMessageType.connectionTerminate.rawValue, forKey: .type)
        }
    }
}
