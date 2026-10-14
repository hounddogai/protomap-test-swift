@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualNetworkNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualNetworkNoticeStore = Referrals.newMemoryManualNetworkNoticeStore()
        let item = Referrals.newManualNetworkNotice("code-18", name: "name-434")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
