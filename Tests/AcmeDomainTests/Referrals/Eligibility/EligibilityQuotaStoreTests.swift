@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityQuotaStore = Referrals.newMemoryEligibilityQuotaStore()
        let item = Referrals.newEligibilityQuota("code-390", label: "label-417")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
