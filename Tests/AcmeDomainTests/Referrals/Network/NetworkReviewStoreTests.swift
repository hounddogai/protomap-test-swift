@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkReviewStore = Referrals.newMemoryNetworkReviewStore()
        let item = Referrals.newNetworkReview("code-713", name: "name-769")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
