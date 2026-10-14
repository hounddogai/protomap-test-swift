@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLegacyClosureLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LegacyClosureLedgerStore = Referrals.newMemoryLegacyClosureLedgerStore()
        let item = Referrals.newLegacyClosureLedger("code-532", name: "name-368")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
