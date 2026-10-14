@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormLedgerStore = Consent.newMemoryConsentFormLedgerStore()
        let item = Consent.newConsentFormLedger("code-836", title: "title-284")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
