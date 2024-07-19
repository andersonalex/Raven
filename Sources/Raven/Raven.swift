//
//  Raven.swift
//  
//
//  Created by Alex Anderson on 6/15/23.
//

import Foundation
import Combine

open class Raven {
    
    // MARK: - Private Properties

    private let defaultDelegate = DefaultDelegate()
    private unowned var delegate: Raven.Delegate

    private let baseURL: URL
    
    // MARK: - Initializers

    public init(delegate: Raven.Delegate? = nil, baseURL: URL) {
        self.delegate = delegate ?? defaultDelegate
        self.baseURL = baseURL
    }
    
    // MARK: - Private Methods

    private func generateURLRequest<EndpointReturnType>(forEndpoint endpoint: Raven.Endpoint<EndpointReturnType>) -> URLRequest? {
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

    private func performRequest<ResponseDataType>(_ endpoint: Raven.Endpoint<ResponseDataType>) async throws -> Raven.Response<ResponseDataType> {

        guard var request = generateURLRequest(forEndpoint: endpoint), let url = request.url else {
            throw RavenError.invalidEndpoint
        }

        let headerConfiguration = delegate.getHttpHeader(endpoint: endpoint)

        for (fieldName, value) in headerConfiguration {
            request.setValue(value, forHTTPHeaderField: fieldName)
        }

        let (data, response) = try await delegate.networkRequestHandler.data(for: request)

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

            return Raven.Response(
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
    
    // MARK: - Public Interface - Structured Concurrency/Async Await
    
    open func request<EndpointReturnType>(_ endpoint: Raven.Endpoint<EndpointReturnType>) async throws -> EndpointReturnType {
        return (try await self.performRequest(endpoint)).data
    }
    
    open func request(_ endpoint: Raven.Endpoint<EmptyResponse>) async throws {
        _ = try await self.performRequest(endpoint)
    }
    
    open func fullRequest<EndpointReturnType>(_ endpoint: Raven.Endpoint<EndpointReturnType>) async throws -> Raven.Response<EndpointReturnType> {
        return try await self.performRequest(endpoint)
    }
    
    // MARK: - Public Interface - Callback Closures
    
    open func request<EndpointReturnType>(_ endpoint: Raven.Endpoint<EndpointReturnType>, onComplete: @escaping (Result<EndpointReturnType, Error>) -> Void) {
        Task.detached {
            do {
                let result = try await self.performRequest(endpoint)
                onComplete(.success(result.data))
            } catch let error {
                onComplete(.failure(error))
            }
        }
    }
    
    open func request<EmptyResponse>(_ endpoint: Raven.Endpoint<EmptyResponse>, onComplete: @escaping (Result<Void, Error>) -> Void) {
        Task.detached {
            do {
                _ = try await self.performRequest(endpoint)
                onComplete(.success(()))
            } catch let error {
                onComplete(.failure(error))
            }
        }
    }
    
    open func fullRequest<EndpointReturnType>(_ endpoint: Raven.Endpoint<EndpointReturnType>, onComplete: @escaping (Result<Raven.Response<EndpointReturnType>, Error>) -> Void) {
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
    
    open func request<EndpointReturnType>(_ endpoint: Raven.Endpoint<EndpointReturnType>) -> Future<EndpointReturnType, Error> {
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
    
    open func request<EmptyResponse>(_ endpoint: Raven.Endpoint<EmptyResponse>) -> Future<Void, Error> {
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
    
    open func fullRequest<EndpointReturnType>(_ endpoint: Raven.Endpoint<EndpointReturnType>) -> Future<Raven.Response<EndpointReturnType>, Error> {
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
