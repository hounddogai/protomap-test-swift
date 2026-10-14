@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotLedgerStore = Referrals.newMemorySlotLedgerStore()
        let item = Referrals.newSlotLedger("code-212", name: "name-233")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
