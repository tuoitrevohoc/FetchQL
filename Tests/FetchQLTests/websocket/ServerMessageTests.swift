//
//  File.swift
//
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import XCTest
import Foundation
@testable import FetchQL

final class ServerMessageTests: XCTestCase {
    
    func testEncoding() throws {
        let decoder = JSONDecoder()
        var message = try decoder.decode(
            ServerMessage.self,
            from: #"{"type":"GQL_CONNECTION_ACK"}"#
                    .data(using: .utf8)!)
        
        guard case .connectionAck = message else {
            XCTFail("Should be connectionAck not \(message)")
            return
        }
        
        message = try decoder.decode(
            ServerMessage.self,
            from: #"{"type":"GQL_DATA","id":"123","payload":"Hello World"}"#
                    .data(using: .utf8)!
        )
        
        if case .data(let id, let payload) = message {
            XCTAssertEqual("123", id)
            XCTAssertEqual("Hello World", try payload.get(as: String.self))
        } else {
            XCTFail("Should has type of .data")
        }
    }
    
}
