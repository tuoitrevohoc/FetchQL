import XCTest
import Combine
import FetchQL

final class FetchQLTests: XCTestCase {
    
    class ApiKeyPlugin: FetchQLPlugIn {
        let apiKey = "da2-kp5nkn4vibflfm2lomr2yjwnp4"
        
        func decorate(request: inout URLRequest, forWebSocket isWebSocket: Bool) {
            request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
    }
    
    struct StockInfo: Codable {
        let name: String
        let symbol: String
    }
    
    struct QueryResult: Codable {
        let stocks: [StockInfo]
    }
    
    static let endPoint = URL(string: "https://fgetgc2rcnawzgkobid4wphsre.appsync-api.ap-southeast-1.amazonaws.com/graphql")!
    var cancellable: AnyCancellable?
    let fetchQL = FetchQL(endPoint: endPoint, plugin: ApiKeyPlugin())
    
    func testQuery() throws {
        let requestFinished = expectation(description: "Request finished")
        let query = """
           query Stocks($query: String) {
               stocks(query: $query) {
                   name
                   symbol
               }
           }
        """
        
        cancellable = fetchQL.query(query, variables: [ "query": "AMZ"], for: QueryResult.self)
            .sink(receiveCompletion: { completion in
                
                switch completion {
                    case .failure:
                        XCTFail("Query should success")
                    case .finished:
                        requestFinished.fulfill()
                }
            }){ result in
                XCTAssertEqual(2, result.stocks.count)
                XCTAssertEqual("AMZN", result.stocks[0].symbol)
            
            }
        
        wait(for: [requestFinished], timeout: 5.0)
    }
    
    func testQuery_error() throws {
        let requestFinished = expectation(description: "Request finished")
        let query = """
           query Stocks($query: String) {
               stoscks(query: $query) {
                   name
                   symbol
               }
           }
        """
        
        cancellable = fetchQL.query(query, variables: [ "query": "AMZ"], for: QueryResult.self)
            .sink(receiveCompletion: { completion in
                
                switch completion {
                    case .failure(let error):
                        switch error {
                        case .responseError(let errors):
                            XCTAssertEqual(1, errors.count)
                        default:
                            XCTFail("Should return error from server error!")
                        }
                    case .finished:
                        XCTFail("Query should not success")
                }
        
                requestFinished.fulfill()
            }){ result in
                XCTFail("Query should not success")
            }
        
        wait(for: [requestFinished], timeout: 5.0)
    }

    static var allTests = [
        ("testExample", testQuery),
    ]
}
