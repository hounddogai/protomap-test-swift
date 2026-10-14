@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceBatchStore = RevenueCycle.newMemoryRemittanceBatchStore()
        let item = RevenueCycle.newRemittanceBatch("code-389", name: "name-81")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
