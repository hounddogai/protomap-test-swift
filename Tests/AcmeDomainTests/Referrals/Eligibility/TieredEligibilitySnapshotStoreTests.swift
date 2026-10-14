@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredEligibilitySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredEligibilitySnapshotStore = Referrals.newMemoryTieredEligibilitySnapshotStore()
        let item = Referrals.newTieredEligibilitySnapshot("code-645", title: "title-741")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
