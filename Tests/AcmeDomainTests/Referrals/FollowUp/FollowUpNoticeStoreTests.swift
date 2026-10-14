@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpNoticeStore = Referrals.newMemoryFollowUpNoticeStore()
        let item = Referrals.newFollowUpNotice("code-495", name: "name-413")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
