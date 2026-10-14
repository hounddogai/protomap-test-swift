@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveClaimSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveClaimSummaryStore = RevenueCycle.newMemoryAdaptiveClaimSummaryStore()
        let item = RevenueCycle.newAdaptiveClaimSummary("code-971", title: "title-630")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
