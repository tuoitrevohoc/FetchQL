import Foundation
import Combine

struct FetchQLQueryRequest<Parameter: Encodable>: Encodable {
    var query: String
    var variables: Parameter
}

/// The FetchQL client
struct FetchQL {
    
    /// the endpoint
    let endPoint: URL
    
    /// the provider
    let provider: ClientProvider
    
    init(endPoint: URL, provider: ClientProvider = DefaultClientProvider()) {
        self.endPoint = endPoint
        self.provider = provider
    }
    
    /// Execute a query
    ///
    /// - Parameters:
    ///   - string: graphql query
    ///   - parameter: the parameter
    /// - Returns:
    func query<ParameterType: Encodable, ResponseType: Decodable>(
        _ query: String,
        parameter: ParameterType,
        for type: ResponseType.Type
    ) throws -> AnyPublisher<ResponseType, FetchQLError> {
        
        let session = URLSession.shared
        let encoder = JSONEncoder()
        let queryRequest = FetchQLQueryRequest(query: query, variables: parameter)
        
        var request = provider.request(for: endPoint)
        request.httpMethod = "POST"
        request.addValue("Content-Type", forHTTPHeaderField: "application/json")
        request.httpBody = try encoder.encode(queryRequest)
        
        return session.dataTaskPublisher(for: request)
                .map { $0.data }
                .decode(type: FetchQLResponse.self, decoder: JSONDecoder())
                .tryMap{ try $0.data(type: type) }
                .mapError { FetchQLError.from(error: $0) }
                .eraseToAnyPublisher()
    }
}
