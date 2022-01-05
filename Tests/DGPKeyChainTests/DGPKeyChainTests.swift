import XCTest
@testable import DGPKeyChain

struct DGPKeyChainResult {
    let status: OSStatus
    let queryResult: AnyObject?
    
}
protocol DGPKeyChainStore {
    func get(_ query: [String: AnyObject]) -> DGPKeyChainResult
}

enum DGPKeyChainError: Error {
    case itemNotFound
    case unhandled
}

class DGPKeyChainManager {
    let service: String
    
    init(service: String) {
        self.service = service
    }
    
    func get(_ key: String) throws -> String? {
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
                let data = existingItem[kSecValueData as String] as? Data,
              let value = String(data: data, encoding: .utf8) else {
                  throw DGPKeyChainError.unhandled
              }
        
        return value
    }
    
    func set(_ key: String, withValue value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw DGPKeyChainError.unhandled
        }
        
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
            var query = createQuery(key)
            query[kSecValueData as String] = data as AnyObject
            
            let status = SecItemAdd(query as CFDictionary, nil)
            
            guard status == noErr else {
                throw DGPKeyChainError.unhandled
            }
        }
    }
    
    
    
    func delete(_ key: String) throws {
        let query = createQuery(key) as CFDictionary
        let status = SecItemDelete(query)
        guard status == noErr  || status == errSecItemNotFound else {
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

final class DGPKeyChainTests: XCTestCase {
    
    func test_get_withNoExistingValue_throwItemNotFoundError() {
        let sut = makeSUT()
        let key = "someKey2"

        XCTAssertThrowsError(try sut.get(key), "", { error in
            XCTAssertEqual(error as! DGPKeyChainError, .itemNotFound)
        })
    }
    
    func test_set_withStringValueNotExisting_shouldSaveValue() throws {
        let sut = makeSUT()
        let key = "someKey2"
        let value = "someValue"
        
        try sut.set(key, withValue: value)
        let object = try sut.get(key)
        
        XCTAssertEqual(object, value)
        
        try clean(sut: sut, [key])
    }
    
    func test_set_withStringValueExisting_shouldUpdateValue() throws {
        let sut = makeSUT()
        let key = "someKey2"
        let value = "someValue"
        let anotherValue = "anotherValue"
        
        try sut.set(key, withValue: value)
        try sut.set(key, withValue: anotherValue)
        let object = try sut.get(key)
        
        XCTAssertEqual(object, anotherValue)
        
        try clean(sut: sut, [key])
    }
    
    func test_delete_withExistingKey_shoudDeleteKey() throws {
        let sut = makeSUT()
        let key = "someKey2"
        let value = "someValue"
        try sut.set(key, withValue: value)
        try sut.delete(key)
        XCTAssertThrowsError(try sut.get(key), "", { error in
            XCTAssertEqual(error as! DGPKeyChainError, .itemNotFound)
        })
        
        try clean(sut: sut, [key])
    }
    
    //MARK: - Helpers
    
    private func makeSUT() -> DGPKeyChainManager {
        let service = "some.service"
        let manager = DGPKeyChainManager(service: service)
        return manager
    }
    
    private func clean(sut: DGPKeyChainManager, _ keys: [String]) throws {
        try keys.forEach {
            try sut.delete($0)
        }
    }
    
}
