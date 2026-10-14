@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryDefaultClosureLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.DefaultClosureLedgerStore = Referrals.newMemoryDefaultClosureLedgerStore()
        let item = Referrals.newDefaultClosureLedger("code-62", title: "title-615")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
