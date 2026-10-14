@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkClaimStore = Referrals.newMemoryNetworkClaimStore()
        let item = Referrals.newNetworkClaim("code-776", title: "title-745")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
