@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultProxyRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultProxyRuleStore = Consent.newMemoryDefaultProxyRuleStore()
        let item = Consent.newDefaultProxyRule("code-109", label: "label-887")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
