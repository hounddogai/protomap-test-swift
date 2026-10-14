@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageMappingStore = Consent.newMemoryLanguageMappingStore()
        let item = Consent.newLanguageMapping("code-658", label: "label-751")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
