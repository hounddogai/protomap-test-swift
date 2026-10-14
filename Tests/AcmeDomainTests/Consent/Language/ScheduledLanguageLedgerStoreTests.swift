@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledLanguageLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledLanguageLedgerStore = Consent.newMemoryScheduledLanguageLedgerStore()
        let item = Consent.newScheduledLanguageLedger("code-101", name: "name-526")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
