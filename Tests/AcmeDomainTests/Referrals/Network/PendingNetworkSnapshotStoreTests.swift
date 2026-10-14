@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingNetworkSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingNetworkSnapshotStore = Referrals.newMemoryPendingNetworkSnapshotStore()
        let item = Referrals.newPendingNetworkSnapshot("code-220", title: "title-599")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
