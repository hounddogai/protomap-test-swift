@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimaryEligibilityQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimaryEligibilityQuotaStore = Referrals.newMemoryPrimaryEligibilityQuotaStore()
        let item = Referrals.newPrimaryEligibilityQuota("code-891", label: "label-124")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
