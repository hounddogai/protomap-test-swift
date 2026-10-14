@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPrimaryNetworkTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PrimaryNetworkTierStore = Referrals.newMemoryPrimaryNetworkTierStore()
        let item = Referrals.newPrimaryNetworkTier("code-771", name: "name-172")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
