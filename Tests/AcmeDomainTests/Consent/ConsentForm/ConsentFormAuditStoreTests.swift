@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormAuditStore = Consent.newMemoryConsentFormAuditStore()
        let item = Consent.newConsentFormAudit("code-12", name: "name-585")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
