@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormPreferenceStore = Consent.newMemoryConsentFormPreferenceStore()
        let item = Consent.newConsentFormPreference("code-619", name: "name-216")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
