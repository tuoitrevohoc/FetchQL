//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-13.
//

import Foundation

public struct AppSyncPlugin: FetchQLPlugIn {
    
    /// the apiKey
    let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// Decorate the request
    ///
    /// - Parameters:
    ///   - request: the request
    ///   - isWebSocket: is this a http request
    public func decorate(request: inout URLRequest, forWebSocket isWebSocket: Bool) {
        if isWebSocket {
            if  let host = request.url?.host,
                let urlString = getWebsocketUrl(endPoint: request.url?.absoluteString) {
                let headers = [ "host": host, "x-api-key": apiKey ]
                let encoder = JSONEncoder()
                
                if let data = try? encoder.encode(headers),
                    let url = URL(string: "\(urlString)?header=\(data.base64EncodedString())&payload=e30="){
                    request = URLRequest(url: url)
                }
            }
        } else {
            request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
    }
    
    /// Get the websocket url from the socket url
    ///
    /// - Parameter endPoint: endPoint
    /// - Returns: the websocket URL
    fileprivate func getWebsocketUrl(endPoint: String?) -> String? {
        return endPoint?
            .replacingOccurrences(of: ".appsync-api.", with: ".appsync-realtime-api.")
            .replacingOccurrences(of: "http", with: "ws")
    }
    
    /// Get The message coder
    ///
    /// - Parameter endPoint: the endpoint to sign the the quest
    /// 
    /// - Returns: the message coder
    public func messageCoder(for endPoint: URL) -> MessageCoder {
        AppSyncCoder(endPoint: endPoint, apiKey: apiKey)
    }
}
