@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpTierStore = Referrals.newMemoryFollowUpTierStore()
        let item = Referrals.newFollowUpTier("code-428", label: "label-176")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
