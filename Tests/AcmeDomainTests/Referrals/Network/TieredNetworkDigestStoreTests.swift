@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredNetworkDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredNetworkDigestStore = Referrals.newMemoryTieredNetworkDigestStore()
        let item = Referrals.newTieredNetworkDigest("code-905", name: "name-613")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
