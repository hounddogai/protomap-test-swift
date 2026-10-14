@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkSnapshotStore = Referrals.newMemoryNetworkSnapshotStore()
        let item = Referrals.newNetworkSnapshot("code-999", label: "label-276")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
