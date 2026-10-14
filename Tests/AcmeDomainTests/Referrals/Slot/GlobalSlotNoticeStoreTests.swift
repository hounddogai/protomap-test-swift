@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalSlotNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalSlotNoticeStore = Referrals.newMemoryGlobalSlotNoticeStore()
        let item = Referrals.newGlobalSlotNotice("code-105", title: "title-167")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
