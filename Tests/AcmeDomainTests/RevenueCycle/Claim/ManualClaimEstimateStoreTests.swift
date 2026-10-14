@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualClaimEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualClaimEstimateStore = RevenueCycle.newMemoryManualClaimEstimateStore()
        let item = RevenueCycle.newManualClaimEstimate("code-271", name: "name-723")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
