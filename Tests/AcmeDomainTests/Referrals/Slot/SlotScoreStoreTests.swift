@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotScoreStore = Referrals.newMemorySlotScoreStore()
        let item = Referrals.newSlotScore("code-502", label: "label-127")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
