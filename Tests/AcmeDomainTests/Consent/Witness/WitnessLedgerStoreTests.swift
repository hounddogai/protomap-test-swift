@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessLedgerStore = Consent.newMemoryWitnessLedgerStore()
        let item = Consent.newWitnessLedger("code-790", title: "title-588")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
