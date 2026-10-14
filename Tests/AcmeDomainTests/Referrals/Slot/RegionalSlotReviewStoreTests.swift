@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalSlotReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalSlotReviewStore = Referrals.newMemoryRegionalSlotReviewStore()
        let item = Referrals.newRegionalSlotReview("code-921", title: "title-782")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
