@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredNetworkEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredNetworkEntryStore = Referrals.newMemoryTieredNetworkEntryStore()
        let item = Referrals.newTieredNetworkEntry("code-889", title: "title-356")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
