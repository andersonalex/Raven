//
//  OptionalProtocol.swift
//  
//
//  Created by Alex Anderson on 6/16/23.
//

import Foundation

/// A protocol that Optional conforms to, useful to check whether a type is optional
protocol OptionalProtocol {}
extension Optional: OptionalProtocol {}
