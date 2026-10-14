@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialReviewStore = RevenueCycle.newMemoryDenialReviewStore()
        let item = RevenueCycle.newDenialReview("code-660", name: "name-565")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
