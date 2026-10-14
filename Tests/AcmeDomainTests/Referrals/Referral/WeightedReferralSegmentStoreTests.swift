@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedReferralSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedReferralSegmentStore = Referrals.newMemoryWeightedReferralSegmentStore()
        let item = Referrals.newWeightedReferralSegment("code-839", title: "title-688")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
