//
//  Raven_Public_Interface.swift
//
//
//  Created by Alex Anderson on 6/19/23.
//

import Foundation
import Combine

// MARK: - Structured Concurrency
public extension Raven {

    func request<EndpointReturnType>(_ endpoint: RavenEndpoint<EndpointReturnType>) async throws -> EndpointReturnType {
        return (try await self.performRequest(endpoint)).data
    }

    func request(_ endpoint: RavenEndpoint<EmptyResponse>) async throws {
        _ = try await self.performRequest(endpoint)
    }

    func fullRequest<EndpointReturnType>(_ endpoint: RavenEndpoint<EndpointReturnType>) async throws -> RavenResponse<EndpointReturnType> {
        return try await self.performRequest(endpoint)
    }

}

// MARK: - Callback Closures
public extension Raven {

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

}

// MARK: - Combine
public extension Raven {

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
