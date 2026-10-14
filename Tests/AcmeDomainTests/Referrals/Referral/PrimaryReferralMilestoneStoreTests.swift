@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimaryReferralMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimaryReferralMilestoneStore = Referrals.newMemoryPrimaryReferralMilestoneStore()
        let item = Referrals.newPrimaryReferralMilestone("code-916", title: "title-17")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
