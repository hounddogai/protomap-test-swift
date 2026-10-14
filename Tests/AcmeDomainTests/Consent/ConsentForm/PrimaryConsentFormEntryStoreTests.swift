@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPrimaryConsentFormEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PrimaryConsentFormEntryStore = Consent.newMemoryPrimaryConsentFormEntryStore()
        let item = Consent.newPrimaryConsentFormEntry("code-123", name: "name-94")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
