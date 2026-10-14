@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilitySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilitySnapshotStore = Referrals.newMemoryEligibilitySnapshotStore()
        let item = Referrals.newEligibilitySnapshot("code-844", label: "label-340")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
