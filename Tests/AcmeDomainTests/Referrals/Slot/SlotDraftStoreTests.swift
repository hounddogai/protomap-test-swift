@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotDraftStore = Referrals.newMemorySlotDraftStore()
        let item = Referrals.newSlotDraft("code-533", label: "label-516")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
