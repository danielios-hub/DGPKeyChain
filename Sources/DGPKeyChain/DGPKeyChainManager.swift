//
//  File.swift
//  
//
//  Created by Daniel Gallego Peralta on 5/1/22.
//

import Foundation

public final class DGPKeyChainManager: DGPKeyChainStore {
    private let service: String
    
    public init(service: String) {
        self.service = service
    }
    
    //MARK: - Get
    
    public func get(_ key: String) throws -> String? {
        guard let data = try getData(key),
              let value = String(data: data, encoding: .utf8) else {
                  throw DGPKeyChainError.unhandled
              }
        
        return value
    }
    
    public func get<T: Decodable>(_ key: String, withType type: T.Type) throws -> T {
        guard let data = try getData(key),
              let value = try? JSONDecoder().decode(type, from: data) else {
                  throw DGPKeyChainError.unhandled
              }
        
        return value
    }
    
    //MARK: - Set
    
    public func set(_ key: String, withValue value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw DGPKeyChainError.notCodable
        }
        
        try set(key, data: data)
    }
    
    public func set<T: Encodable>(_ key: String, withValue value: T) throws {
        guard let data = try? JSONEncoder().encode(value) else {
            throw DGPKeyChainError.notCodable
        }
        
        try set(key, data: data)
    }
    
    //MARK: - Delete
    
    public func delete(_ key: String) throws {
        let query = createQuery(key) as CFDictionary
        let status = SecItemDelete(query)
        guard status == noErr  || status == errSecItemNotFound else {
            throw DGPKeyChainError.unhandled
        }
    }
    
}

extension DGPKeyChainManager {
    
    private func getData(_ key: String) throws -> Data? {
        var query = createQuery(key)
        
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        guard status != errSecItemNotFound else {
            throw DGPKeyChainError.itemNotFound
        }

        guard status == noErr else {
            throw DGPKeyChainError.unhandled
        }
        
        guard let existingItem = queryResult as? [String: AnyObject],
              let data = existingItem[kSecValueData as String] as? Data else {
                  return nil
              }
        
        return data
    }
    
    private func set(_ key: String, data: Data) throws {
        do {
            _ = try get(key)
            
            let query = createQuery(key) as CFDictionary
            
            var attributedToUpdate = [String: AnyObject]()
            attributedToUpdate[kSecValueData as String] = data as AnyObject
            
            let status = SecItemUpdate(query, attributedToUpdate as CFDictionary)
            
            guard status == noErr else {
                throw DGPKeyChainError.unhandled
            }
        } catch DGPKeyChainError.itemNotFound {
            try update(key, data: data)
        }
    }
    
    private func update(_ key: String, data: Data) throws {
        var query = createQuery(key)
        query[kSecValueData as String] = data as AnyObject
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == noErr else {
            throw DGPKeyChainError.unhandled
        }
    }
    
    private func createQuery(_ key: String) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject
        query[kSecAttrAccount as String] = key as AnyObject
        return query
    }
    
}
