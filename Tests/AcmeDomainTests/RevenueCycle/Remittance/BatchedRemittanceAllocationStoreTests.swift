@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedRemittanceAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedRemittanceAllocationStore = RevenueCycle.newMemoryBatchedRemittanceAllocationStore()
        let item = RevenueCycle.newBatchedRemittanceAllocation("code-750", label: "label-742")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
