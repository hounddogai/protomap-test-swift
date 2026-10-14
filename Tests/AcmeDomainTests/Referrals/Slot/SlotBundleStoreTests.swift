@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotBundleStore = Referrals.newMemorySlotBundleStore()
        let item = Referrals.newSlotBundle("code-584", label: "label-229")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
