@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityMilestoneStore = Referrals.newMemoryEligibilityMilestoneStore()
        let item = Referrals.newEligibilityMilestone("code-224", name: "name-370")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
