# Raven
Lightweight, modern, API documenting networking library for interfacing with RESTful APIs on Apple platforms. Written 100% in Swift.

## A Simple Example
In this example, let's say we need to access the api `api.somecompany.com` and specifically the login endpoint (`/login'). If the API call is successful, the response from this endpoint will be the following json containing the user's auth token:
```json
{
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6Ik..."
}
```

The first step to using Raven to access this API is setting up the endpoint and response object (a `Decodable`): 
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
Next, we declare a `Raven` with the baseURL to the API:
```swift
let raven = Raven(baseURL: URL(string: "api.somecompany.com")!)
```
Finally, we call the API endpoint by passing it to one of `Raven`'s `.request()` functions. We could use structured concurrency (async/await), callback closures, or Combine. We'll use structured concurrency here.
```swift
func login() async throws {
    let response = try await raven.request(.login(username: "alexanderson", password: "LETMEIN"))

    self.token = response.token
}
```

## Endpoints
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

## Performing Requests
API requests are performed using either the `request()` or `fullRequest()` functions. If information is needed from the full response of the API (including HTTP status code and headers), then use `fullRequest()`. If only the response data is needed, use `request()`.
```swift

let donut = try await donutRaven.request(.getDonut(27))
print(donut.title)

let fullDonutResponse = try await donutRaven.fullRequest(.getDonut(45))
if fullDonutResponse.statusCode == .success {
    print(donut.title)
}
```
Requests can be performed using either structured concurrency (async/await), closure callbacks, or combine:
```swift
class LoginService {

    let raven = Raven(baseURL: URL(string: "api.somecompany.com")!)
    var token: String?

    func loginAsync() async throws {
        let response = try await raven.request(.login(username: "alexanderson", password: "LETMEIN"))

        token = response.token
    }

    func loginClosure() {
        raven.request(.login(username: "alexanderson", password: "LETMEIN")) { response in
            switch response {
            case .success(let response):
                self.token = response.token
            case .failure:
                // handle error
                break
            }
        }
    }

    func loginCombine() {
        raven.request(.login(username: "alexanderson", password: "LETMEIN"))
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // handle potential errors
            } receiveValue: { response in
                self.token = response.token
            }
    }

}
```

## RavenDelegate
In order to provide more specific functionality, you can create a delegate class that conforms to `RavenDelegate`. This delegate can intervene during certain stages of Raven's procedures to attach headers, provide json encoders and decoders, decorate requests, and provide errors. Defaults to all of these methods are provided, so you can implement only the methods you need.
```swift
public protocol RavenDelegate: AnyObject {
    func getHttpHeader<T>(endpoint: RavenEndpoint<T>) -> [String: String]
    func generateError(fromUrl url: URL, statusCode: HTTPStatusCode, responseData: Data) -> Error
    func decorate(request: URLRequest) -> URLRequest

    var jsonEncoder: JSONEncoder { get }
    var jsonDecoder: JSONDecoder { get }
}
```
### Errors
The fact that errors will occur when interfacing with an API is not an after thought for Raven, it's an assumption that's baked in to Raven's design. Different APIs will have different types of errors that frontend software will have to handle differently. Since Raven could never account for all of the different types of errors that any API could produce, Raven provides a method for the developer to generate their own errors given an HTTP response with an unsuccessful status code (in the 400s). This is the `generateError()` method of `RavenDelegate`:
```swift
class MyRavenDelegate: RavenDelegate {
    struct MyErrorType: Error, Decodable {
        let code: Int
        let message: String
        let userMessage: String
    }

    func generateError(fromUrl url: URL, statusCode: HTTPStatusCode, responseData: Data) -> Error {
        if let error = try? JSONDecoder().decode(MyErrorType.self, from: responseData) {
            return error
        } else {
            return RavenError.responseError(statusCode)
        }
    }
}
```
Note that if a `generateError()` implementation with a provided delegate does not exist, Raven will return an instance of the default error type: `RavenError`.

## Coming Soon
- Better documentation
- Better support for creating a `Raven` mock
- A full test suite