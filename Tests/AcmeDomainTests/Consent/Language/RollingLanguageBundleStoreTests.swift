@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingLanguageBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingLanguageBundleStore = Consent.newMemoryRollingLanguageBundleStore()
        let item = Consent.newRollingLanguageBundle("code-464", label: "label-204")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
