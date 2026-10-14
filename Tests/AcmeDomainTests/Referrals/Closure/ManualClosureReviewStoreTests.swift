@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualClosureReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualClosureReviewStore = Referrals.newMemoryManualClosureReviewStore()
        let item = Referrals.newManualClosureReview("code-595", name: "name-880")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
