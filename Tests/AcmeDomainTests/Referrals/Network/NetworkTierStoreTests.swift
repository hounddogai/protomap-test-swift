@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkTierStore = Referrals.newMemoryNetworkTierStore()
        let item = Referrals.newNetworkTier("code-20", title: "title-847")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
