import XCTest
import DGPKeyChain

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
    
    func test_set_withCodableValueNotExisting_shouldSaveValue() throws {
        let sut = makeSUT()
        let key = "someKey2"
        let value: Int = 100
        
        try sut.set(key, withValue: value)
        let object = try sut.get(key, withType: Int.self)
        
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
    
    func test_set_withCodableValueExisting_shouldUpdateValue() throws {
        let sut = makeSUT()
        let key = "someKey2"
        let value: Int = 100
        let anotherValue: Int = 101
        
        try sut.set(key, withValue: value)
        try sut.set(key, withValue: anotherValue)
        let object = try sut.get(key, withType: Int.self)
        
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
    
    private func makeSUT() -> DGPKeyChainStore {
        let service = "some.service"
        let manager = DGPKeyChainManager(service: service)
        return manager
    }
    
    private func clean(sut: DGPKeyChainStore, _ keys: [String]) throws {
        try keys.forEach {
            try sut.delete($0)
        }
    }
    
}
