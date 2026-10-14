@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkRollupStore = Referrals.newMemoryNetworkRollupStore()
        let item = Referrals.newNetworkRollup("code-914", name: "name-924")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
