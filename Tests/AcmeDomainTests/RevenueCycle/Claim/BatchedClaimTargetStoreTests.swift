@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedClaimTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedClaimTargetStore = RevenueCycle.newMemoryBatchedClaimTargetStore()
        let item = RevenueCycle.newBatchedClaimTarget("code-23", label: "label-38")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
