import XCTest
@testable import DGPKeyChain

protocol DGPKeyChainStore {
    
}

class DGPKeyChainManager {
    let store: DGPKeyChainStore
    let tag: String
    
    init(store: DGPKeyChainStore, tag: String) {
        self.store = store
        self.tag = tag
    }
    
    func get(_ key: String) -> String? {
        return nil
    }
    
}

final class DGPKeyChainTests: XCTestCase {
    
    func test_init_doesNotSaveData() {
        let tag = "some.tag"
        let storeSpy = KeyChainStoreSpy()
        let _ = DGPKeyChainManager(store: storeSpy, tag: tag)
        XCTAssert(storeSpy.messages.isEmpty)
    }
    
    func test_get_withNoExistingValue_returnNil() {
        let key = "someKey"
        let tag = "some.tag"
        let storeSpy = KeyChainStoreSpy()
        let manager = DGPKeyChainManager(store: storeSpy, tag: tag)
        
        let receivedValue = manager.get(key)
        XCTAssertNil(receivedValue)
    }
    
    private class KeyChainStoreSpy: DGPKeyChainStore {
        enum Message {
            
        }
        
        var messages = [Message]()
    }
}
