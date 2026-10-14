@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpPolicyStore = Referrals.newMemoryFollowUpPolicyStore()
        let item = Referrals.newFollowUpPolicy("code-506", label: "label-920")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
