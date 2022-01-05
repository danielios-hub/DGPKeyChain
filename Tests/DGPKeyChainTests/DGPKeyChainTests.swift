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
    
}

final class DGPKeyChainTests: XCTestCase {
    
    func test_init_doesNotSaveData() {
        let tag = "some.tag"
        let storeSpy = KeyChainStoreSpy()
        let _ = DGPKeyChainManager(store: storeSpy, tag: tag)
        XCTAssert(storeSpy.messages.isEmpty)
    }
    
    private class KeyChainStoreSpy: DGPKeyChainStore {
        enum Message {
            
        }
        
        var messages = [Message]()
    }
}
