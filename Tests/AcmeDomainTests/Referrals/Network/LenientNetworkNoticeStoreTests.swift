@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLenientNetworkNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LenientNetworkNoticeStore = Referrals.newMemoryLenientNetworkNoticeStore()
        let item = Referrals.newLenientNetworkNotice("code-131", title: "title-785")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
