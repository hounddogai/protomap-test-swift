@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralMilestoneStore = Referrals.newMemoryReferralMilestoneStore()
        let item = Referrals.newReferralMilestone("code-390", name: "name-942")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
