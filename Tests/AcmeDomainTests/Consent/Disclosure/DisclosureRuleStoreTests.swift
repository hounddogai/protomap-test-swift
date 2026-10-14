@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureRuleStore = Consent.newMemoryDisclosureRuleStore()
        let item = Consent.newDisclosureRule("code-361", label: "label-765")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
