//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-11.
//

import Foundation

/// the fetch QL response Error
struct FetchQLResponseError: Decodable {
    /// message of the error
    let message: String
    
    /// description of the error
    let description: String?
}

/// The response class
struct FetchQLResponse: Decodable {
    
    /// errors if there are errors
    let errors: [FetchQLResponseError]?
    
    /// the current container
    let current: KeyedDecodingContainer<CodingKeys>
    
    /// manually decode
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case errors = "errors"
    }
}

extension FetchQLResponse {
    
    /// Fetch json
    /// - Parameter decoder: the decoder
    /// - Throws: the description
    init(from decoder: Decoder) throws {
        current = try decoder.container(keyedBy: CodingKeys.self)
        
        if current.contains(.errors) {
            errors = try current.decode([FetchQLResponseError].self, forKey: .errors)
        } else {
            errors = nil
        }
    }

    
    /// Lazily decode the data with the type
    /// - Returns: the data
    func data<Response: Decodable>(of type: Response.Type) throws -> Response {
        
        if let errors = errors {
            throw FetchQLError.responseError(errors: errors)
        }
        
        return try current.decode(type, forKey: .data)
    }
}
