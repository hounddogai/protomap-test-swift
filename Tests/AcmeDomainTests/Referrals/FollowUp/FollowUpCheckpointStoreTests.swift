@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpCheckpointStore = Referrals.newMemoryFollowUpCheckpointStore()
        let item = Referrals.newFollowUpCheckpoint("code-599", title: "title-698")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
