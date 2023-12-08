//
//  Raven.swift
//  
//
//  Created by Alex Anderson on 6/15/23.
//

import Foundation

class DefaultRavenDelegate: RavenDelegate {}

public class Raven {

    private let defaultDelegate = DefaultRavenDelegate()
    private unowned var delegate: RavenDelegate

    private let baseURL: URL

    public init(delegate: RavenDelegate? = nil, baseURL: URL) {
        self.delegate = delegate ?? defaultDelegate
        self.baseURL = baseURL
    }

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

    internal func performRequest<ResponseDataType>(_ endpoint: RavenEndpoint<ResponseDataType>) async throws -> RavenResponse<ResponseDataType> {

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

}
