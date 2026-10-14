@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualNetworkMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualNetworkMilestoneStore = Referrals.newMemoryManualNetworkMilestoneStore()
        let item = Referrals.newManualNetworkMilestone("code-466", title: "title-807")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
