//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation
import Combine

protocol SubscriptionManager {
    
    /// Add subscription
    ///
    /// - Parameter id: the id of subscription
    func addSubscripton(id: String, handler: SubscriptionHandler)
    
    /// Remove subscription
    /// - Parameter id: the subscription with Id
    func removeSubscription(id: String)
}


/// create a FetchQLPublisher
class SubscriptionPublisher: Publisher {
    typealias Output = MessagePayload
    typealias Failure = FetchQLError
    
    /// the fetchQL
    private let manager: SubscriptionManager?
    private let id: String
    
    /// Initialize with a manager
    /// - Parameter manager: the manager of this subscription
    init(manager: SubscriptionManager?, withId id: String) {
        self.manager = manager
        self.id = id
    }
    
    /// Receive a new subscriber
    ///
    /// - Parameter subscriber: the subscriber
    func receive<SubscriberType>(subscriber: SubscriberType)
        where SubscriberType: Subscriber,
        SubscriberType.Failure == SubscriptionPublisher.Failure,
        SubscriberType.Input == SubscriptionPublisher.Output {
    
        let subscription = FetchQLSubscription(subscriber: subscriber, id: id, manager: manager)
            
        manager?.addSubscripton(id: id, handler: subscription)
        subscriber.receive(subscription: subscription)
    }
}
