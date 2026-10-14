@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedReferralSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedReferralSnapshotStore = Referrals.newMemoryCappedReferralSnapshotStore()
        let item = Referrals.newCappedReferralSnapshot("code-292", name: "name-745")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
