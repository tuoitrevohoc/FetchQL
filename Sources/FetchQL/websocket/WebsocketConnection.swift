//
//  File.swift
//  
//
//  Created by Tran Thien Khiem on 2020-05-12.
//

import Foundation

protocol WebSocketConnectionDelegate {
    /// Process the message
    /// - Parameter message: message
    func processMessage(message: ServerMessage)
    
    /// Process the error
    ///
    /// - Parameter error: the error
    func processError(error: Error)
}

enum ConnectionState: Equatable {
    case initializing
    case active
}

class WebSocketConnection {
    
    /// The websocket task
    fileprivate var task: URLSessionWebSocketTask
    fileprivate let delegate: WebSocketConnectionDelegate?
    
    // @TODO: replace this with a real queue
    fileprivate var queues = [URLSessionWebSocketTask.Message]()
    fileprivate var state = ConnectionState.initializing
    fileprivate var coder: MessageCoder
    
    /// generate a connection for request
    init(for request: URLRequest, coder: MessageCoder, delegate: WebSocketConnectionDelegate?) {
        let session = URLSession.shared
        
        self.delegate = delegate
        self.coder = coder
        
        task = session.webSocketTask(with: request)
        nextMessage()
        task.resume()
    }
    
    /// De initialize
    deinit {
        queueMessage(message: ClientMessages.connectionTerminate)
    }
    
    /// Next message
    private func nextMessage() {
        task.receive {[weak self] result in
            self?.receiveMessage(result: result)
            self?.nextMessage()
        }
    }
    
    /// Send a message
    ///
    /// - Parameter message: the message to send
    func queueMessage<Variable: Encodable>(message: ClientMessage<Variable>) {
#if DEBUG
        print("Send message: \(message)")
#endif
        
        if let stringMessage = encode(message: message) {
            if case .connectionInit = message {
               send(message: stringMessage)
            } else {
                queues.append(stringMessage)

                resume()
            }
        }
    }
    
    /// Encode the message
    ///
    /// - Parameter message: the message
    /// - Returns: Websocket Message
    func encode<Variable: Encodable>(message: ClientMessage<Variable>) -> URLSessionWebSocketTask.Message? {
        
        if let value = try? coder.encode(message: message) {
            return .string(value)
        }
        
        return nil
    }
    
    /// Resume sending the message
    func resume() {
        if queues.count > 0 && state == .active {
            let message = queues.remove(at: 0)
            send(message: message)
        }
    }
    
    /// send message
    ///
    /// - Parameter message: message
    fileprivate func send(message: URLSessionWebSocketTask.Message) {
        task.send(message) { [weak self] error in
            if let error = error {
                self?.processError(error: error)
            }
            
            self?.resume()
        }
    }
    
    /// The message handler
    /// - Parameter result: the result
    fileprivate func receiveMessage(result: Result<URLSessionWebSocketTask.Message, Error>) {
        switch result {
        case .success(let message):
            processMessage(message: message)
        case .failure(let error):
            processError(error: error)
        }
    }
    
    /// Process message
    ///
    /// - Parameter message: the message
    fileprivate func processMessage(message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data:
            processError(error: FetchQLError.notSupported)
        case .string(let value):
            if let serverMessage = try? coder.decode(payload: value) {
                processMessage(message: serverMessage)
            }
        @unknown default:
            processError(error: FetchQLError.notSupported)
        }
    }
    
    /// Process the message
    /// - Parameter message: message
    fileprivate func processMessage(message: ServerMessage) {
#if DEBUG
        print("Receive message: \(message)")
#endif
        switch message {
        case .connectionAck:
            state = .active
            resume()
        default:
            delegate?.processMessage(message: message)
        }
    }
    
    /// Process the error
    /// 
    /// - Parameter error: the error
    fileprivate func processError(error: Error) {
        delegate?.processError(error: error)
    }
}
