@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedConsentFormRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedConsentFormRuleStore = Consent.newMemoryCappedConsentFormRuleStore()
        let item = Consent.newCappedConsentFormRule("code-799", name: "name-259")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
