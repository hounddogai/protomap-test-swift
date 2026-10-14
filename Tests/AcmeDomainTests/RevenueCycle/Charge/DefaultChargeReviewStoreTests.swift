@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultChargeReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultChargeReviewStore = RevenueCycle.newMemoryDefaultChargeReviewStore()
        let item = RevenueCycle.newDefaultChargeReview("code-285", label: "label-531")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
