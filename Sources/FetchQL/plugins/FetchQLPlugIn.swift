//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation

public protocol FetchQLPlugIn {
    
    /// Decorate request
    ///
    /// - Parameter request: the request
    func decorate(request: inout URLRequest, forWebSocket isWebSocket: Bool)
    
    /// The message coder for requet
    ///
    /// - Parameter request: the request decorator
    func messageCoder(for endPoint: URL) -> MessageCoder
}

extension FetchQLPlugIn {
    
    /// create a message coder for the request
    ///
    /// - Parameter request: the request
    /// - Returns: message coder
    public func messageCoder(for endPoint: URL) -> MessageCoder {
        DefaultMessageCoder()
    }
}
