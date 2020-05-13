//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation

/// Message coder error
enum MessageCoderError: Error {
    case failure
}

/// the message coder
public protocol MessageCoder {
    
    /// WebSocket Message Coder
    ///
    /// - Parameter clientMessage: the client message
    func encode<Variable: Encodable>(message: ClientMessage<Variable>) throws -> String
    
    /// WebScoket message coder
    ///
    /// - Parameter data: the data
    /// - Returns Server Message
    func decode(payload: String) throws -> ServerMessage
}

/// the defautl message coder
extension MessageCoder {
    
    /// Default encoder
    /// - Parameter message: the message
    /// - Returns: description
    public func encode<Variable: Encodable>(message: ClientMessage<Variable>) throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        
        guard let value = String(data: data, encoding: .utf8) else {
            throw MessageCoderError.failure
        }
        
        return value
    }
    
    /// The server message
    ///
    /// - Parameter data: data to decode
    /// - Throws: exception when decoding
    /// - Returns: the server message
    public func decode(payload: String) throws -> ServerMessage {
        guard let data = payload.data(using: .utf8) else {
            throw MessageCoderError.failure
        }
        
        let decoder = JSONDecoder()
        
        return try decoder.decode(ServerMessage.self, from: data)
    }
}

/// Default message coder
public struct DefaultMessageCoder: MessageCoder {
}
