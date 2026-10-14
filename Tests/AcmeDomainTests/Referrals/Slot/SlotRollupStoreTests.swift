@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotRollupStore = Referrals.newMemorySlotRollupStore()
        let item = Referrals.newSlotRollup("code-508", title: "title-190")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
