@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureMilestoneStore = Referrals.newMemoryClosureMilestoneStore()
        let item = Referrals.newClosureMilestone("code-19", title: "title-671")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
