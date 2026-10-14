@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralPlanStore = Referrals.newMemoryReferralPlanStore()
        let item = Referrals.newReferralPlan("code-781", title: "title-629")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
