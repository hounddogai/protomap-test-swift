@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedClaimEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedClaimEstimateStore = RevenueCycle.newMemoryBatchedClaimEstimateStore()
        let item = RevenueCycle.newBatchedClaimEstimate("code-305", title: "title-546")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
