@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureReviewStore = Referrals.newMemoryClosureReviewStore()
        let item = Referrals.newClosureReview("code-943", name: "name-445")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
