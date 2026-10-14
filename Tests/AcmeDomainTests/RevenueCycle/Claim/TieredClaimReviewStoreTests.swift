@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredClaimReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredClaimReviewStore = RevenueCycle.newMemoryTieredClaimReviewStore()
        let item = RevenueCycle.newTieredClaimReview("code-522", label: "label-357")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
