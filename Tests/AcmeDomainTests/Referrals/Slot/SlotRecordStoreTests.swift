@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotRecordStore = Referrals.newMemorySlotRecordStore()
        let item = Referrals.newSlotRecord("code-864", title: "title-702")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
