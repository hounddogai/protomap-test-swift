@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredFollowUpBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredFollowUpBatchStore = Referrals.newMemoryTieredFollowUpBatchStore()
        let item = Referrals.newTieredFollowUpBatch("code-89", title: "title-976")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
