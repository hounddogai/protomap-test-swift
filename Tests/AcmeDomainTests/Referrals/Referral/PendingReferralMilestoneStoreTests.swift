@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingReferralMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingReferralMilestoneStore = Referrals.newMemoryPendingReferralMilestoneStore()
        let item = Referrals.newPendingReferralMilestone("code-27", name: "name-230")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
