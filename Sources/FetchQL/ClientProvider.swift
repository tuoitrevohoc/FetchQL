//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-11.
//

import Foundation

/// The client provider
protocol ClientProvider {
    
    /// given a connection to connect to FetchQL
    func request(for url: URL) -> URLRequest
}
