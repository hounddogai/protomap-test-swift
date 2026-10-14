@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalClosureLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalClosureLedgerStore = Referrals.newMemoryRegionalClosureLedgerStore()
        let item = Referrals.newRegionalClosureLedger("code-487", title: "title-670")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
