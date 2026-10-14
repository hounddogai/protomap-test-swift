@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotMilestoneStore = Referrals.newMemorySlotMilestoneStore()
        let item = Referrals.newSlotMilestone("code-452", name: "name-887")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
