@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryGlobalDisclosureRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.GlobalDisclosureRuleStore = Consent.newMemoryGlobalDisclosureRuleStore()
        let item = Consent.newGlobalDisclosureRule("code-797", label: "label-514")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
