@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryWeightedDenialReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.WeightedDenialReviewStore = RevenueCycle.newMemoryWeightedDenialReviewStore()
        let item = RevenueCycle.newWeightedDenialReview("code-732", name: "name-334")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
