@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryStrictDisclosureLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.StrictDisclosureLedgerStore = Consent.newMemoryStrictDisclosureLedgerStore()
        let item = Consent.newStrictDisclosureLedger("code-132", name: "name-555")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
