@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeReviewStore = RevenueCycle.newMemoryChargeReviewStore()
        let item = RevenueCycle.newChargeReview("code-529", name: "name-253")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
