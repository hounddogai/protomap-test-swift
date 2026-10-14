@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFallbackClosureReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FallbackClosureReviewStore = Referrals.newMemoryFallbackClosureReviewStore()
        let item = Referrals.newFallbackClosureReview("code-369", label: "label-554")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
