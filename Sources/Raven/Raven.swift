//
//  Raven.swift
//  
//
//  Created by Alex Anderson on 6/15/23.
//

import Foundation
import Combine

class DefaultRavenDelegate: RavenDelegate {}

open class Raven {
    
    // MARK: - Private Properties

    private let defaultDelegate = DefaultRavenDelegate()
    private unowned var delegate: RavenDelegate

    private let baseURL: URL
    
    // MARK: - Initializers

    public init(delegate: RavenDelegate? = nil, baseURL: URL) {
        self.delegate = delegate ?? defaultDelegate
        self.baseURL = baseURL
    }
    
    // MARK: - Private Methods

    private func generateURLRequest<EndpointReturnType>(forEndpoint endpoint: RavenEndpoint<EndpointReturnType>) -> URLRequest? {
        guard let url = endpoint.url(fromBase: baseURL) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethod.rawValue

        if EndpointReturnType.self != EmptyResponse.self {
            request.setValue("text/plain", forHTTPHeaderField: "Accept")
        }

        if let requestBody = endpoint.requestBody {
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "content-type")

            switch requestBody {
            case .dict(let dictionary):
                request.httpBody = try? JSONSerialization.data(withJSONObject: dictionary)
            case .encodable(let encodable):
                request.httpBody = try? delegate.jsonEncoder.encode(encodable)
            }
        }

        return request
    }

    private func performRequest<ResponseDataType>(_ endpoint: RavenEndpoint<ResponseDataType>) async throws -> RavenResponse<ResponseDataType> {

        guard var request = generateURLRequest(forEndpoint: endpoint), let url = request.url else {
            throw RavenError.invalidEndpoint
        }

        let headerConfiguration = delegate.getHttpHeader(endpoint: endpoint)

        for (fieldName, value) in headerConfiguration {
            request.setValue(value, forHTTPHeaderField: fieldName)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard
            let httpResponse = response as? HTTPURLResponse,
            let httpStatus = httpResponse.status
        else {
            throw RavenError.unknownError
        }

        if httpStatus.responseType == .success {
            let returnData: ResponseDataType

            if ResponseDataType.self is EmptyResponse.Type {
                returnData = EmptyResponse() as! ResponseDataType
            } else if ResponseDataType.self is OptionalProtocol.Type && httpStatus == .noContent {
                // this is equivalent `nil` - had to do this because of the generic type
                returnData = Optional<Any>.none as! ResponseDataType
            } else {
                do {
                    returnData = try delegate.jsonDecoder.decode(ResponseDataType.self, from: data)
                } catch let error {
                    throw RavenError.parsingError(error)
                }
            }

            return RavenResponse(
                statusCode: httpStatus,
                header: httpResponse.allHeaderFields,
                data: returnData)
        } else {
            throw delegate.generateError(
                fromUrl: url,
                statusCode: httpStatus,
                responseData: data)
        }
    }

    private func data(forRequest request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            return try await URLSession.shared.data(for: request)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    switch (data, response, error) {
                    case (.some(let data), .some(let response), nil):
                        continuation.resume(returning: (data, response))
                    case (_, _, .some(let error)):
                        continuation.resume(throwing: error)
                    default:
                        continuation.resume(throwing: RavenError.unknownError)
                    }
                }
                task.resume()
            }
        }
    }
    
    // MARK: - Public Interface - Structured Concurrency/Async Await
    
    func request<EndpointReturnType>(_ endpoint: RavenEndpoint<EndpointReturnType>) async throws -> EndpointReturnType {
        return (try await self.performRequest(endpoint)).data
    }
    
    func request(_ endpoint: RavenEndpoint<EmptyResponse>) async throws {
        _ = try await self.performRequest(endpoint)
    }
    
    func fullRequest<EndpointReturnType>(_ endpoint: RavenEndpoint<EndpointReturnType>) async throws -> RavenResponse<EndpointReturnType> {
        return try await self.performRequest(endpoint)
    }
    
    // MARK: - Public Interface - Callback Closures
    
    func request<EndpointReturnType>(_ endpoint: RavenEndpoint<EndpointReturnType>, onComplete: @escaping (Result<EndpointReturnType, Error>) -> Void) {
        Task.detached {
            do {
                let result = try await self.performRequest(endpoint)
                onComplete(.success(result.data))
            } catch let error {
                onComplete(.failure(error))
            }
        }
    }
    
    func request<EmptyResponse>(_ endpoint: RavenEndpoint<EmptyResponse>, onComplete: @escaping (Result<Void, Error>) -> Void) {
        Task.detached {
            do {
                _ = try await self.performRequest(endpoint)
                onComplete(.success(()))
            } catch let error {
                onComplete(.failure(error))
            }
        }
    }
    
    func fullRequest<EndpointReturnType>(_ endpoint: RavenEndpoint<EndpointReturnType>, onComplete: @escaping (Result<RavenResponse<EndpointReturnType>, Error>) -> Void) {
        Task.detached {
            do {
                let result = try await self.performRequest(endpoint)
                onComplete(.success(result))
            } catch let error {
                onComplete(.failure(error))
            }
        }
    }
    
    // MARK: - Public Interface - Combine
    
    func request<EndpointReturnType>(_ endpoint: RavenEndpoint<EndpointReturnType>) -> Future<EndpointReturnType, Error> {
        return Future { promise in
            Task.detached {
                do {
                    let result = try await self.performRequest(endpoint)
                    promise(.success(result.data))
                } catch let error {
                    promise(.failure(error))
                }
            }
        }
    }
    
    func request<EmptyResponse>(_ endpoint: RavenEndpoint<EmptyResponse>) -> Future<Void, Error> {
        return Future { promise in
            Task.detached {
                do {
                    _ = try await self.performRequest(endpoint)
                    promise(.success(()))
                } catch let error {
                    promise(.failure(error))
                }
            }
        }
    }
    
    func fullRequest<EndpointReturnType>(_ endpoint: RavenEndpoint<EndpointReturnType>) -> Future<RavenResponse<EndpointReturnType>, Error> {
        return Future { promise in
            Task.detached {
                do {
                    let result = try await self.performRequest(endpoint)
                    promise(.success(result))
                } catch let error {
                    promise(.failure(error))
                }
            }
        }
    }

}
