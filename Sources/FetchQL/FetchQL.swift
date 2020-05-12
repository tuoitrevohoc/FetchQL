import Foundation
import Combine

fileprivate struct FetchQLQueryRequest<Parameter: Encodable>: Encodable {
    /// the fetch query
    var query: String
    
    /// the fetch variables
    var variables: Parameter
}

fileprivate struct FetchQLMutationRequest<Parameter: Encodable>: Encodable {
    /// The mutation String
    var mutation: String
    
    /// The variables
    var variables: Parameter
}

/// The FetchQL client
public class FetchQL {
    
    /// the endpoint
    let endPoint: URL
    
    /// the request decorators
    let decorators: [RequestDecorator]

    /// the result
    public typealias FetchQLPublisher<Response> = AnyPublisher<Response, FetchQLError>
    
    /// Initialize with
    ///
    /// - Parameters:
    ///   - endPoint: the endpoint
    ///   - decorators: The request decorators
    public init(endPoint: URL, decorators: [RequestDecorator] = []) {
        self.endPoint = endPoint
        self.decorators = decorators
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
        parameter: ParameterType,
        for type: ResponseType.Type
    ) -> AnyPublisher<ResponseType, FetchQLError> {
        Result.Publisher(.failure(FetchQLError.responseError(errors: [])))
            .eraseToAnyPublisher()
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
    
    /// Create and prepare the request
    ///
    /// - Parameter url: the url
    fileprivate func createRequest() -> URLRequest {
        var request = URLRequest(url: endPoint)
        decorators.forEach { $0.decorate(request: &request)}
        
        return request
    }
}
