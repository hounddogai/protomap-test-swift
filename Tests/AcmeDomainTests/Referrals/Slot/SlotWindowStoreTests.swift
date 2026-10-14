@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotWindowStore = Referrals.newMemorySlotWindowStore()
        let item = Referrals.newSlotWindow("code-406", label: "label-744")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
