@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageAuditStore = Consent.newMemoryLanguageAuditStore()
        let item = Consent.newLanguageAudit("code-733", name: "name-567")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
