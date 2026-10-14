@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledLanguageRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledLanguageRuleStore = Consent.newMemoryScheduledLanguageRuleStore()
        let item = Consent.newScheduledLanguageRule("code-894", label: "label-83")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
