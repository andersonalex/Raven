//
//  NetworkRequestHandler.swift
//
//
//  Created by Alex Anderson on 7/19/24.
//

import Foundation

public extension Raven {
    
    protocol NetworkRequestHandler {
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse)
        
    }
    
}

extension URLSession: Raven.NetworkRequestHandler {}
