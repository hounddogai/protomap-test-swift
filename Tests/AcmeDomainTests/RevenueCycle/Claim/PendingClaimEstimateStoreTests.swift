@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingClaimEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingClaimEstimateStore = RevenueCycle.newMemoryPendingClaimEstimateStore()
        let item = RevenueCycle.newPendingClaimEstimate("code-608", label: "label-609")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
