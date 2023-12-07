//
//  CombineRaven.swift
//  
//
//  Created by Alex Anderson on 6/19/23.
//

import Foundation
import Combine

struct LoginResponse: Decodable {
    let token: String
}

extension RavenEndpoint {

    static func login(username: String, password: String) -> RavenEndpoint<LoginResponse> {
        .init(
            httpMethod: .post,
            path: "/login",
            responseDataType: LoginResponse.self,
            requiresAuth: false)
    }

}

class LoginService {

    let raven = Raven(baseURL: URL(string: "Apple.com")!)
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
