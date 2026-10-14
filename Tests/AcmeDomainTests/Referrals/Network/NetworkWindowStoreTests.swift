@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkWindowStore = Referrals.newMemoryNetworkWindowStore()
        let item = Referrals.newNetworkWindow("code-304", title: "title-917")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
