@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralSnapshotStore = Referrals.newMemoryReferralSnapshotStore()
        let item = Referrals.newReferralSnapshot("code-262", title: "title-191")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
