@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictSlotLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictSlotLedgerStore = Referrals.newMemoryStrictSlotLedgerStore()
        let item = Referrals.newStrictSlotLedger("code-795", title: "title-306")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
