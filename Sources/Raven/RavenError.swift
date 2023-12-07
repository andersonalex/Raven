//
//  RavenError.swift
//  
//
//  Created by Alex Anderson on 6/15/23.
//

import Foundation

public enum RavenError: Error {
    case responseError
    case invalidEndpoint
    case unknownError
    case parsingError(Error)
}
