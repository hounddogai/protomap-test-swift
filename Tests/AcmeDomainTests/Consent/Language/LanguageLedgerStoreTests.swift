@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageLedgerStore = Consent.newMemoryLanguageLedgerStore()
        let item = Consent.newLanguageLedger("code-102", name: "name-834")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
