@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredReferralMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredReferralMilestoneStore = Referrals.newMemoryTieredReferralMilestoneStore()
        let item = Referrals.newTieredReferralMilestone("code-613", title: "title-714")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
