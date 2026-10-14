@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormCycleStore = Consent.newMemoryConsentFormCycleStore()
        let item = Consent.newConsentFormCycle("code-867", name: "name-360")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
