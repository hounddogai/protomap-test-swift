@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredSlotSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredSlotSnapshotStore = Referrals.newMemoryTieredSlotSnapshotStore()
        let item = Referrals.newTieredSlotSnapshot("code-358", name: "name-812")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
