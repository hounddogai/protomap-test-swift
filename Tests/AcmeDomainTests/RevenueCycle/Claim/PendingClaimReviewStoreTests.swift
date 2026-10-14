@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingClaimReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingClaimReviewStore = RevenueCycle.newMemoryPendingClaimReviewStore()
        let item = RevenueCycle.newPendingClaimReview("code-540", title: "title-820")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
