@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryManualConsentFormEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ManualConsentFormEntryStore = Consent.newMemoryManualConsentFormEntryStore()
        let item = Consent.newManualConsentFormEntry("code-876", name: "name-93")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
