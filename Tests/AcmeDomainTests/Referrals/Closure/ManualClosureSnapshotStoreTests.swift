@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualClosureSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualClosureSnapshotStore = Referrals.newMemoryManualClosureSnapshotStore()
        let item = Referrals.newManualClosureSnapshot("code-376", label: "label-151")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
