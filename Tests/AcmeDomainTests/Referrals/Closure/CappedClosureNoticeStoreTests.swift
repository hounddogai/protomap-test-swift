@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedClosureNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedClosureNoticeStore = Referrals.newMemoryCappedClosureNoticeStore()
        let item = Referrals.newCappedClosureNotice("code-482", name: "name-726")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
