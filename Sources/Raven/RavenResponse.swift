//
//  RavenResponse.swift
//  
//
//  Created by Alex Anderson on 6/20/23.
//

import Foundation

public struct RavenResponse<ResponseDataType> {
    let statusCode: HTTPStatusCode
    let header: [AnyHashable: Any]
    let data: ResponseDataType
}
