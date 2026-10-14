@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedLanguageBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedLanguageBundleStore = Consent.newMemoryCappedLanguageBundleStore()
        let item = Consent.newCappedLanguageBundle("code-213", label: "label-389")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
