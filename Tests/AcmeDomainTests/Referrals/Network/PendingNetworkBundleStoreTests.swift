@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingNetworkBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingNetworkBundleStore = Referrals.newMemoryPendingNetworkBundleStore()
        let item = Referrals.newPendingNetworkBundle("code-969", name: "name-442")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
