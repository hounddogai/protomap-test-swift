@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedSlotSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedSlotSnapshotStore = Referrals.newMemoryBatchedSlotSnapshotStore()
        let item = Referrals.newBatchedSlotSnapshot("code-593", title: "title-16")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
