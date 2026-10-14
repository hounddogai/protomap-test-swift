@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalEligibilityQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalEligibilityQuotaStore = Referrals.newMemorySeasonalEligibilityQuotaStore()
        let item = Referrals.newSeasonalEligibilityQuota("code-316", name: "name-77")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
