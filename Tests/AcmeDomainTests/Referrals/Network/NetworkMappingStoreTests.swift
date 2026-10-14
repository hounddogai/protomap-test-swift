@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkMappingStore = Referrals.newMemoryNetworkMappingStore()
        let item = Referrals.newNetworkMapping("code-337", name: "name-847")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
