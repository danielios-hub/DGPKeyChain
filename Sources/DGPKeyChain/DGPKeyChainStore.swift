//
//  File.swift
//  
//
//  Created by Daniel Gallego Peralta on 5/1/22.
//

import Foundation

public enum DGPKeyChainError: Error {
    case itemNotFound
    case notCodable
    case unhandled
}

public protocol DGPKeyChainStore {
    func get(_ key: String) throws -> String?
    func get<T: Decodable>(_ key: String, withType type: T.Type) throws -> T
    func set(_ key: String, withValue value: String) throws
    func set<T: Encodable>(_ key: String, withValue value: T) throws
    func delete(_ key: String) throws
}
