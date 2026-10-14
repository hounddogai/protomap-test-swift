@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotTemplateStore = Referrals.newMemorySlotTemplateStore()
        let item = Referrals.newSlotTemplate("code-639", label: "label-752")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
