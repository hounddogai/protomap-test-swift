@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalReferralAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalReferralAuditStore = Referrals.newMemorySeasonalReferralAuditStore()
        let item = Referrals.newSeasonalReferralAudit("code-468", label: "label-829")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
