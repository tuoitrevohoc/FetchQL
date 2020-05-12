//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-11.
//

import Foundation

/// The client provider
public protocol RequestDecorator {
    
    /// Decorate the request
    func decorate(request: inout URLRequest)
}
