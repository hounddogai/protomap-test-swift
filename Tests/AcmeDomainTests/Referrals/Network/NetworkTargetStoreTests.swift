@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkTargetStore = Referrals.newMemoryNetworkTargetStore()
        let item = Referrals.newNetworkTarget("code-319", name: "name-881")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
