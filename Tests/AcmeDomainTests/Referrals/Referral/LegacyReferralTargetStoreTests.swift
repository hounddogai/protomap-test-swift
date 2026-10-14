@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacyReferralTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacyReferralTargetStore = Referrals.newMemoryLegacyReferralTargetStore()
        let item = Referrals.newLegacyReferralTarget("code-973", title: "title-487")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
