//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation

/// The incoming message
enum ServerMessageType: String {
    case connectionError = "connection_error"
    case connectionAck = "connection_ack"
    case data = "data"
    case error = "error"
    case complete = "complete"
    case keepAlive = "ka"
}

enum MessageDecodeError: Error {
    case unknownType
}

/// Lazily decode the message
public struct MessagePayload {
    
    /// the decoder container
    let container: KeyedDecodingContainer<CodingKeys>
    
    /// the coding keys
    enum CodingKeys: CodingKey {
        case data
    }
    
    /// Get the result as a specific type
    ///
    /// - Parameter type: type to get
    /// - Throws: exception
    /// - Returns: the description
    func get<Result: Decodable>(as type: Result.Type) throws -> Result {
        try container.decode(type, forKey: .data)
    }
}

public enum ServerMessage {
    case connectionError
    case connectionAck
    case data(id: String, payload: MessagePayload)
    case error(id: String, payload: MessagePayload)
    case complete(id: String)
    case keepAlive
}


extension ServerMessage: Decodable {
    enum CodingKeys: CodingKey {
        case type
        case id
        case payload
    }
    
    /// Decode the server message from the payload
    /// - Parameter decoder: decoder
    /// - Throws: the error incase decoding failed
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeValue = try container.decode(String.self, forKey: .type)
        let type = ServerMessageType(rawValue: typeValue)
        
        switch type {
        case .connectionAck:
            self = .connectionAck
        case .connectionError:
            self = .connectionError
        case .complete:
            let id = try container.decode(String.self, forKey: .id)
            self = .complete(id: id)
        case .keepAlive:
            self = .keepAlive
        case .data:
            let id = try container.decode(String.self, forKey: .id)
            let dataContainer = try container.nestedContainer(keyedBy: MessagePayload.CodingKeys.self, forKey: .payload)
            let payload = MessagePayload(container: dataContainer)
            self = .data(id: id, payload: payload)
        case .error:
            let id = try container.decode(String.self, forKey: .id)
            let dataContainer = try container.nestedContainer(keyedBy: MessagePayload.CodingKeys.self, forKey: .payload)
            let payload = MessagePayload(container: dataContainer)
            self = .error(id: id, payload: payload)
        case .none:
            throw MessageDecodeError.unknownType
        }
    
    }
}
