@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotScheduleStore = Referrals.newMemorySlotScheduleStore()
        let item = Referrals.newSlotSchedule("code-827", title: "title-982")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
