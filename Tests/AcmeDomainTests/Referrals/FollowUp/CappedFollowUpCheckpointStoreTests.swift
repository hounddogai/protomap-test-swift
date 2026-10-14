@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedFollowUpCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedFollowUpCheckpointStore = Referrals.newMemoryCappedFollowUpCheckpointStore()
        let item = Referrals.newCappedFollowUpCheckpoint("code-854", title: "title-643")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
