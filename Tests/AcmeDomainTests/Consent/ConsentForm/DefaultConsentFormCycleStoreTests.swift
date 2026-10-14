@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultConsentFormCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultConsentFormCycleStore = Consent.newMemoryDefaultConsentFormCycleStore()
        let item = Consent.newDefaultConsentFormCycle("code-713", title: "title-289")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
