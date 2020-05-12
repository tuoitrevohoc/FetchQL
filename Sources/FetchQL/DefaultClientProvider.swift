//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-11.
//

import Foundation

struct DefaultClientProvider: ClientProvider {
    
    /// Create a request
    /// - Parameter url: the request
    /// - Returns: the request
    func request(for url: URL) -> URLRequest {
        return URLRequest(url: url)
    }
}
