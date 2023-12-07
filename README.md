# Raven
Lightweight, API documenting networking library written for Apple platform development. Written in 100% Swift.

# A Simple Example
The first step to using Raven to access an API is setting up your endpoints. 
```swift
struct LoginResponse: Decodable {
    let token: String
}

extension RavenEndpoint {

    static func login(username: String, password: String) -> RavenEndpoint<LoginResponse> {
        .init(
            httpMethod: .post,
            path: "/login",
            requestBody: [
                "userName": username,
                "password": password
            ],
            responseDataType: LoginResponse.self)
    }

}
```
Next, declare your Raven with the baseURL to your API:
```swift
let raven = Raven(baseURL: URL(string: "api.somecompany.com")!)
```
Finally, call your API endpoint by passing it to one of `Raven`'s `.request()` functions. You can use structured concurrency (async/await), callback closures, or Combine (we'll use structured concurrency here)
```swift
func login() async throws {
    let response = try await raven.request(.login(username: "alexanderson", password: "LETMEIN"))

    self.token = response.token
}
```

# Endpoints
A `RavenEndpoint` serves as blueprints for your API - it gives your `Raven` everything it needs to fetch and parse data from an endpoint of your API and it serves as a form of API documentation within your project.
```swift
extension RavenEndpoint {

    static func getDonuts(
        createdFrom: Date? = nil,
        createdTo: Date? = nil,
        pageSize: Int? = nil,
        pageNumber: Int? = nil
    ) -> RavenEndpoint<PaginatedResponse<Donut>> {
        .init(
            httpMethod: .get,
            path: "/donuts",
            urlParameters: [
                "CreatedFrom": createdFrom?.string(.iso8601Full),
                "CreatedTo": createdTo?.string(.iso8601Full),
                "size": pageSize,
                "page": pageNumber
            ],
            responseDataType: PaginatedResponse<Donut>.self)
    }

    static func getDonut(id: Int) -> RavenEndpoint<Donut> {
        .init(
            httpMethod: .get,
            path: "/donuts/\(id)",
            responseDataType: Donut.self)
    }

    static func createDonut(_ donutData: Donut) -> RavenEndpoint<EmptyResponse> {
        .init(
            httpMethod: .post,
            path: "/donuts/",
            requestBody: CreateDonutRequestBody(donutData)
            responseDataType: EmptyResponse.self)
    }

    static func modifyDonut(id: Int, _ donutData: Donut) -> RavenEndpoint<EmptyResponse> {
        .init(
            httpMethod: .put,
            path: "/donuts/\(id)",
            requestBody: DonutUpdateRequestBody(donutData),
            responseDataType: EmptyResponse.self)
    }

    static func deleteDonut(id: Int) -> RavenEndpoint<EmptyResponse> {
        .init(
            httpMethod: .delete,
            path: "/donuts/\(id)",
            responseDataType: EmptyResponse.self)
    }

}
```
A request body can be specified using either an encodable OR a dictionary
```swift
// dictionary implementation
extension RavenEndpoint {

    static func changePassword(currentPassword: String, newPassword: String) -> RavenEndpoint<EmptyResponse> {
        .init(
            httpMethod: .put,
            path: "/User/password",
            requestBody: [
                "currentPassword": currentPassword,
                "newPassword": newPassword
            ],
            responseDataType: EmptyResponse.self
        )
    }

}
```
```swift
// Encodable Implementation
struct ChangePasswordRequestBody: Encodable {
    let currentPassword: String
    let newPassword: String
}

extension RavenEndpoint {

    static func changePassword(currentPassword: String, newPassword: String) -> RavenEndpoint<EmptyResponse> {
        .init(
            httpMethod: .put,
            path: "/User/password",
            requestBody: ChangePasswordRequestBody(
                currentPassword: currentPassword,
                newPassword: newPassword),
            responseDataType: EmptyResponse.self
        )
    }

}
```
