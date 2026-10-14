@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackDenialReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackDenialReviewStore = RevenueCycle.newMemoryFallbackDenialReviewStore()
        let item = RevenueCycle.newFallbackDenialReview("code-891", label: "label-544")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
