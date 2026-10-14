@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryAdaptiveReferralSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.AdaptiveReferralSummaryStore = Referrals.newMemoryAdaptiveReferralSummaryStore()
        let item = Referrals.newAdaptiveReferralSummary("code-440", title: "title-469")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
