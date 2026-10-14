@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkOverrideStore = Referrals.newMemoryNetworkOverrideStore()
        let item = Referrals.newNetworkOverride("code-542", name: "name-201")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
