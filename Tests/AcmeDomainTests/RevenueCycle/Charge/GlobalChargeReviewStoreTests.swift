@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalChargeReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalChargeReviewStore = RevenueCycle.newMemoryGlobalChargeReviewStore()
        let item = RevenueCycle.newGlobalChargeReview("code-672", name: "name-168")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
