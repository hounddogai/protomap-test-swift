@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotOverrideStore = Referrals.newMemorySlotOverrideStore()
        let item = Referrals.newSlotOverride("code-916", title: "title-359")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
