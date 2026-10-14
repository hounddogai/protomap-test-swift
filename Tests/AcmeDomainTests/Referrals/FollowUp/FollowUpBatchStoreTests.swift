@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpBatchStore = Referrals.newMemoryFollowUpBatchStore()
        let item = Referrals.newFollowUpBatch("code-873", name: "name-245")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
