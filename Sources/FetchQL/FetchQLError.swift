//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation

/// the graphql error
enum FetchQLError: Error {
    case requestError(error: Error)
    case responseError(errors: [FetchQLResponseError])
    
    static func from(error: Error) -> FetchQLError {
        switch error {
        case FetchQLError.responseError(let errors):
            return .responseError(errors: errors)
        default:
            return .requestError(error: error)
        }
    }
}
