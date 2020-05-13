import Foundation
import Combine

enum SubscriptionState: Equatable {
    case initialized
    case acknownledged
    case cancelled
}

/// The FetchQL client
public class FetchQL: SubscriptionManager, WebSocketConnectionDelegate {
    
    /// the endpoint
    let endPoint: URL
    
    /// the request decorators
    let plugin: FetchQLPlugIn?
    
    /// the list of subscriptions
    var subscriptions = [String: SubscriptionHandler]()
    
    /// the subscription states
    var subscriptionStates = [String: SubscriptionState]()
    
    /// the socket connection
    var connection: WebSocketConnection? = nil

    /// the result
    public typealias FetchQLPublisher<Response> = AnyPublisher<Response, FetchQLError>
    
    /// Initialize with
    ///
    /// - Parameters:
    ///   - endPoint: the endpoint
    ///   - decorators: The request decorators
    public init(endPoint: URL, plugin: FetchQLPlugIn? = nil) {
        self.endPoint = endPoint
        self.plugin = plugin
    }
    
    /// Execute a GraphQL Query
    ///
    /// - Parameters:
    ///   - query: the query
    ///   - variables: list of variables
    ///   - type: expected response type
    /// - Returns: Publisher of the result
    public func query<ParameterType: Encodable, ResponseType: Decodable>(
        _ query: String,
        variables: ParameterType,
        for type: ResponseType.Type
    ) -> FetchQLPublisher<ResponseType> {
        let queryRequest = FetchQLQueryRequest(query: query, variables: variables)
        return execute(request: queryRequest, for: type)
    }
    
    /// Execute a GraphQL Mutation
    ///
    /// - Parameters:
    ///   - query: the query
    ///   - variables: list of variables
    ///   - type: expected response type
    /// - Returns: Publisher of the result
    public func mutation<ParameterType: Encodable, ResponseType: Decodable>(
        _ mutation: String,
        variables: ParameterType,
        for type: ResponseType.Type
    ) -> FetchQLPublisher<ResponseType> {
        let queryRequest = FetchQLMutationRequest(mutation: mutation, variables: variables)
        return execute(request: queryRequest, for: type)
    }
    
    /// Subscribe to a chanel
    /// - Parameters:
    ///   - query: the query
    ///   - parameter: the parameter
    ///   - type: type of the expected data
    ///
    /// - Returns: a publisher
    public func subscribe<ParameterType: Encodable, ResponseType: Decodable>(
        _ query: String,
        variables: ParameterType,
        for type: ResponseType.Type
    ) -> FetchQLPublisher<ResponseType> {
        initWebsocketConncetion()
        
        let id = UUID().uuidString.lowercased()
        connection?.queueMessage(message: .start(id: id, query: query, variables: variables))
        
        return SubscriptionPublisher(manager: self, withId: id)
            .tryMap { try $0.get(as: type) }
            .mapError { FetchQLError.from(error: $0) }
            .eraseToAnyPublisher()
    }
    
    /// get socket connection
    fileprivate func initWebsocketConncetion() {
        if connection == nil {
            var request = createRequest()
            
            plugin?.decorate(request: &request, forWebSocket: true)
            request.addValue("graphql-ws", forHTTPHeaderField: "Sec-WebSocket-Protocol")
            request.addValue("8NEI3eqmwrjbJ+2sT4KrsA==", forHTTPHeaderField: "Sec-WebSocket-Key")
            request.addValue("x-webkit-deflate-frame", forHTTPHeaderField: "Sec-WebSocket-Extensions")
            
            let coder = plugin?.messageCoder(for: endPoint) ?? DefaultMessageCoder()
            
            connection = WebSocketConnection(for: request, coder: coder, delegate: self)
            connection?.queueMessage(message: ClientMessages.connectionInit)
        }
    }
    
    /// Execute a query
    ///
    /// - Parameters:
    ///   - string: graphql query
    ///   - parameter: the parameter
    /// - Returns:
    fileprivate func execute<RequestType: Encodable, ResponseType: Decodable>(
        request graphQlRequest: RequestType,
        for type: ResponseType.Type
    ) -> FetchQLPublisher<ResponseType> {
        
        let session = URLSession.shared
        let encoder = JSONEncoder()
        
        do {
            var request = createRequest()
            
            plugin?.decorate(request: &request, forWebSocket: false)
            
            request.httpMethod = "POST"
            request.addValue("Content-Type", forHTTPHeaderField: "application/json")
            request.httpBody = try encoder.encode(graphQlRequest)
            
            return session.dataTaskPublisher(for: request)
                    .map { $0.data }
                    .decode(type: FetchQLResponse.self, decoder: JSONDecoder())
                    .tryMap{ try $0.data(of: type) }
                    .mapError { FetchQLError.from(error: $0) }
                    .eraseToAnyPublisher()
        } catch {
            return Result.Publisher(.failure(FetchQLError.from(error: error)))
                    .eraseToAnyPublisher()
        }
    }
    
    /// Process message from server
    ///
    /// - Parameter message: message
    func processMessage(message: ServerMessage) {
        switch message {
        case .data(let id, let payload):
            subscriptions[id]?.onMessage(payload: payload)
        case .startAck(let id):
            acknowledge(id: id)
        case .error(let id, let payload):
            if let error = try? payload.get(as: ErrorData.self) {
                subscriptions[id]?.onError(error: .responseError(errors: [error]))
            }
        default: break
        }
    }
    
    /// Process error
    /// - Parameter error: error
    func processError(error: Error) {
        // @TODO: throw error to everyone
        print(error)
    }
    
    /// Acknownledge a subscription
    ///
    /// - Parameter id: the subscrion
    fileprivate func acknowledge(id: String) {
        let state = subscriptionStates[id]
        if case .initialized = state {
            subscriptionStates[id] = .acknownledged
        } else if case .cancelled = subscriptionStates[id] {
            removeSubscription(id: id)
        }
    }
    
    /// Create and prepare the request
    ///
    /// - Parameter url: the url
    fileprivate func createRequest() -> URLRequest {
        return URLRequest(url: endPoint)
    }
    
    /// Add a subscription
    /// - Parameters:
    ///   - id: id of the subscription
    ///   - handler: the handler
    func addSubscripton(id: String, handler: SubscriptionHandler) {
        subscriptions[id] = handler
        subscriptionStates[id] = .initialized
    }
    
    /// Remove subscription
    ///
    /// - Parameter id: id of the subscription
    func removeSubscription(id: String) {
        if subscriptionStates[id] != .initialized {
            connection?.queueMessage(message: ClientMessages.stop(id: id))
            subscriptions.removeValue(forKey: id)
        } else {
            subscriptionStates[id] = .cancelled
        }
    }
}
