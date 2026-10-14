@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationRuleStore = Consent.newMemoryRevocationRuleStore()
        let item = Consent.newRevocationRule("code-193", name: "name-170")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
