@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimAdjustmentStore = RevenueCycle.newMemoryClaimAdjustmentStore()
        let item = RevenueCycle.newClaimAdjustment("code-274", label: "label-242")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
