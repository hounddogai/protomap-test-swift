@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingFollowUpNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingFollowUpNoticeStore = Referrals.newMemoryPendingFollowUpNoticeStore()
        let item = Referrals.newPendingFollowUpNotice("code-18", title: "title-95")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
