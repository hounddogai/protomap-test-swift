@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedRevocationLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedRevocationLedgerStore = Consent.newMemoryCappedRevocationLedgerStore()
        let item = Consent.newCappedRevocationLedger("code-691", name: "name-707")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
