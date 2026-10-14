@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackChargeBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackChargeBatchStore = RevenueCycle.newMemoryFallbackChargeBatchStore()
        let item = RevenueCycle.newFallbackChargeBatch("code-193", name: "name-25")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
