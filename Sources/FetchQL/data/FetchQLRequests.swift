//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation

struct FetchQLQueryRequest<Parameter: Encodable>: Encodable {
    /// the fetch query
    var query: String
    
    /// the fetch variables
    var variables: Parameter
}

struct FetchQLMutationRequest<Parameter: Encodable>: Encodable {
    /// The mutation String
    var mutation: String
    
    /// The variables
    var variables: Parameter
}
