@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotNoticeStore = Referrals.newMemorySlotNoticeStore()
        let item = Referrals.newSlotNotice("code-464", title: "title-42")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
