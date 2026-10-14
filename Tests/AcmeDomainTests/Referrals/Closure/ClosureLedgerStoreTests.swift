@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureLedgerStore = Referrals.newMemoryClosureLedgerStore()
        let item = Referrals.newClosureLedger("code-919", name: "name-570")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
