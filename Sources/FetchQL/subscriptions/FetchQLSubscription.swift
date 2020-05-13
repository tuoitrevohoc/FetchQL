//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation
import Combine

/// The subscription
protocol SubscriptionHandler {
    
    /// the message
    /// - Parameter payload: the message payload
    func onMessage(payload: MessagePayload)
    
    /// the subscription callback
    /// - Parameter error: error
    func onError(error: FetchQLError)
}

final class FetchQLSubscription<SubscriberType: Subscriber>:
        Subscription, SubscriptionHandler
        where SubscriberType.Input == MessagePayload,
              SubscriberType.Failure == FetchQLError {
    
    private var subscriber: SubscriberType?
    private let id: String
    private let manager: SubscriptionManager?
    
    /// Create using a subscriber type
    ///
    /// - Parameters:
    ///   - subscriber: the subscriber
    ///   - id: id of subscription
    ///   - client: the client
    init(subscriber: SubscriberType, id: String, manager: SubscriptionManager?) {
        self.subscriber = subscriber
        self.id = id
        self.manager = manager
    }
    
    /// Nothing here
    /// - Parameter demand: the demand
    func request(_ demand: Subscribers.Demand) {
    }
    
    /// cancel the subscription
    func cancel() {
        if subscriber != nil {
            manager?.removeSubscription(id: id)
        }
        
        subscriber = nil
    }
    
    /// onComing message
    /// - Parameter payload: the message payload
    func onMessage(payload: MessagePayload) {
        print("Calling subscriber receive")
        _ = subscriber?.receive(payload)
    }
    
    /// On Error
    /// - Parameter error: the message error
    func onError(error: FetchQLError) {
        subscriber?.receive(completion: .failure(error))
        cancel()
    }
}
