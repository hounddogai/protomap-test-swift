@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRollingClosureNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RollingClosureNoticeStore = Referrals.newMemoryRollingClosureNoticeStore()
        let item = Referrals.newRollingClosureNotice("code-122", title: "title-535")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
