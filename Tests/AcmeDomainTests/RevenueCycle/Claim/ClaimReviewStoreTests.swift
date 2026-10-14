@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimReviewStore = RevenueCycle.newMemoryClaimReviewStore()
        let item = RevenueCycle.newClaimReview("code-315", name: "name-840")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
