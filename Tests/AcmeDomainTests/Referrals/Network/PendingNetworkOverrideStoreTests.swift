@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingNetworkOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingNetworkOverrideStore = Referrals.newMemoryPendingNetworkOverrideStore()
        let item = Referrals.newPendingNetworkOverride("code-18", name: "name-673")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
