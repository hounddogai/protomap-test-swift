@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotAdjustmentStore = Referrals.newMemorySlotAdjustmentStore()
        let item = Referrals.newSlotAdjustment("code-628", title: "title-947")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
