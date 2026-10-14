@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageOverrideStore = Consent.newMemoryLanguageOverrideStore()
        let item = Consent.newLanguageOverride("code-624", name: "name-765")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
