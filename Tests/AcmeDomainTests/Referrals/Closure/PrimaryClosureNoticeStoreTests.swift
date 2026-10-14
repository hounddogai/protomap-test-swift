@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimaryClosureNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimaryClosureNoticeStore = Referrals.newMemoryPrimaryClosureNoticeStore()
        let item = Referrals.newPrimaryClosureNotice("code-627", title: "title-354")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
