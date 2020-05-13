# FetchQL

A Simple GraphQL Client using Combine Framework


Execute a query:

```
let fetchQL = FetchQL(endPoint: "https://.....")
let query = """
query GetTodo($id: String!) {
    getTodo(id: $id) {
        name
        description
    }
}
"""

let anyCancellable = fetchQL.query(query, variables: ["id": "1"], for: Todo.self)
    .sync(receiveCompletion: { completion in
        print("\(completion)")
    }, receiveValue: { todo in
        printf("\(result.getTodo)")
    })
```

Subscribe to a subscription
```
let fetchQL = FetchQL(endPoint: "https://....")
let subscriptionQuery = """
subscription OnTodoCreated() {
    onTodoCreated() {
        name
        description
    }
}
"""

let anyCancellable = fetchQL.subscribe(subscriptionQuery, variables: [], for: Todo.self)
    .sync(receiveCompletion: { completion in
        print("\(completion)")
    }, receiveValue: { todo in
        printf("\(result.onTodoCreated)")
    })
```

Use an API Key

```
let fetchQL = FetchQL(endPoint: "....", plugin: ApiKeyPlugin(apiKey: "..."))
```

Use with AppSync

```
let fetchQL = FetchQL(endPoint: "....", plugin: AppSyncPlugin(apiKey: "..."))
```
