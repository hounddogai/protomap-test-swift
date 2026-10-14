@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguagePreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguagePreferenceStore = Consent.newMemoryLanguagePreferenceStore()
        let item = Consent.newLanguagePreference("code-546", title: "title-350")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
