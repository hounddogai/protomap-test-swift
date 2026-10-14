@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralPolicyStore = Referrals.newMemoryReferralPolicyStore()
        let item = Referrals.newReferralPolicy("code-396", title: "title-259")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
