@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledFollowUpCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledFollowUpCycleStore = Referrals.newMemoryScheduledFollowUpCycleStore()
        let item = Referrals.newScheduledFollowUpCycle("code-214", title: "title-525")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
