@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackLanguageTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackLanguageTemplateStore = Consent.newMemoryFallbackLanguageTemplateStore()
        let item = Consent.newFallbackLanguageTemplate("code-866", title: "title-38")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
