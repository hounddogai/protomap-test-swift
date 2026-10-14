@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedChargeEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedChargeEntryStore = RevenueCycle.newMemoryBatchedChargeEntryStore()
        let item = RevenueCycle.newBatchedChargeEntry("code-952", label: "label-158")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
