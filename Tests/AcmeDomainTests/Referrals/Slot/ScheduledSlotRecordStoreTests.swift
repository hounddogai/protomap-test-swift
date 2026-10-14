@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledSlotRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledSlotRecordStore = Referrals.newMemoryScheduledSlotRecordStore()
        let item = Referrals.newScheduledSlotRecord("code-597", title: "title-786")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
