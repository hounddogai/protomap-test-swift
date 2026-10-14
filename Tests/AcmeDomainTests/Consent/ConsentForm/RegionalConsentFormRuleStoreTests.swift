@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRegionalConsentFormRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RegionalConsentFormRuleStore = Consent.newMemoryRegionalConsentFormRuleStore()
        let item = Consent.newRegionalConsentFormRule("code-193", name: "name-428")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
