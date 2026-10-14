@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimSummaryStore = RevenueCycle.newMemoryClaimSummaryStore()
        let item = RevenueCycle.newClaimSummary("code-322", label: "label-7")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
