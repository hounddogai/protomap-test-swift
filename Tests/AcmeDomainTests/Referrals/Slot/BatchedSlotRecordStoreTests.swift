@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedSlotRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedSlotRecordStore = Referrals.newMemoryBatchedSlotRecordStore()
        let item = Referrals.newBatchedSlotRecord("code-275", title: "title-891")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
