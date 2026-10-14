@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedRemittanceAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedRemittanceAdjustmentStore = RevenueCycle.newMemoryBatchedRemittanceAdjustmentStore()
        let item = RevenueCycle.newBatchedRemittanceAdjustment("code-889", name: "name-710")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
