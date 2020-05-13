import XCTest
import Combine
import FetchQL

final class FetchQLSubscriptionTests: XCTestCase {
    struct Todo: Codable {
        let id: String
        let name: String
    }
    
    struct SubscriptionResult: Codable {
        let onCreateTodo: Todo
    }
    
    var cancellable: AnyCancellable?

    
    func testSubscription() throws {
        let endPoint = URL(string: "https://6652q43fafcrhgnruwenl4f7i4.appsync-api.ap-southeast-1.amazonaws.com/graphql")!
        let fetchQL = FetchQL(endPoint: endPoint, plugin: AppSyncPlugin(apiKey: "da2-d4iln5ffinf53oropocnocpjsm"))
        
        let requestFinished = expectation(description: "Request finished")
        let query = """
           subscription OnCreateTodo {
               onCreateTodo {
                   id
                   name
               }
           }
        """
        
        cancellable = fetchQL.subscribe(query, variables: [String:String](), for: SubscriptionResult.self)
            .sink(receiveCompletion: { completion in
                
                switch completion {
                    case .failure:
                        XCTFail("Query should success")
                    case .finished:
                        requestFinished.fulfill()
                }
            }){ result in
                print(result.onCreateTodo)
            }
        
        wait(for: [requestFinished], timeout: 80.0)
    }

}
