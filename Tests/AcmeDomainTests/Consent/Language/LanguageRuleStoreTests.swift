@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageRuleStore = Consent.newMemoryLanguageRuleStore()
        let item = Consent.newLanguageRule("code-58", title: "title-340")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
