@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalSlotBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalSlotBatchStore = Referrals.newMemoryRegionalSlotBatchStore()
        let item = Referrals.newRegionalSlotBatch("code-109", title: "title-403")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
