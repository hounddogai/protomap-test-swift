@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkBatchStore = Referrals.newMemoryNetworkBatchStore()
        let item = Referrals.newNetworkBatch("code-552", label: "label-781")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
