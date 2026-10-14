@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedNetworkClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedNetworkClaimStore = Referrals.newMemoryBatchedNetworkClaimStore()
        let item = Referrals.newBatchedNetworkClaim("code-545", label: "label-679")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
