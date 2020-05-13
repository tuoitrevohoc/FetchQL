//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import XCTest
import Foundation
@testable import FetchQL

final class ClientMessageTests: XCTestCase {
    
    fileprivate func encodeJson<Payload: Encodable>(message: ClientMessage<Payload>) -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(message)
        return String(data: data, encoding: .utf8)!
    }
    
    func testEncoding() throws {
        XCTAssertEqual(
            #"{"type":"GQL_CONNECTION_INIT"}"#,
           encodeJson(message: ClientMessages.connectionInit)
        )
        
        XCTAssertEqual(
            #"{"type":"GQL_CONNECTION_TERMINATE"}"#,
            encodeJson(message: ClientMessages.connectionTerminate)
        )
        
        XCTAssertEqual(
            #"{"type":"GQL_START","id":"123","payload":{"query":"select","variables":"123"}}"#,
            encodeJson(message: .start(id: "123", query: "select", variables: "123"))
        )
        
        XCTAssertEqual(
            #"{"type":"GQL_STOP","id":"123"}"#,
            encodeJson(message: ClientMessages.stop(id: "123"))
        )
    }
    
}
