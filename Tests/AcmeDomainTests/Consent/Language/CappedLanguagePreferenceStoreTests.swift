@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedLanguagePreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedLanguagePreferenceStore = Consent.newMemoryCappedLanguagePreferenceStore()
        let item = Consent.newCappedLanguagePreference("code-346", label: "label-864")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
