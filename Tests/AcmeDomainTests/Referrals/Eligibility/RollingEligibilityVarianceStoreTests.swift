@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRollingEligibilityVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RollingEligibilityVarianceStore = Referrals.newMemoryRollingEligibilityVarianceStore()
        let item = Referrals.newRollingEligibilityVariance("code-884", title: "title-709")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
