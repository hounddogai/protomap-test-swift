@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryAdaptiveFollowUpPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.AdaptiveFollowUpPolicyStore = Referrals.newMemoryAdaptiveFollowUpPolicyStore()
        let item = Referrals.newAdaptiveFollowUpPolicy("code-883", label: "label-529")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
