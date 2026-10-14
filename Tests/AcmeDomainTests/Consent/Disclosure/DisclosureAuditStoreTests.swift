@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureAuditStore = Consent.newMemoryDisclosureAuditStore()
        let item = Consent.newDisclosureAudit("code-46", label: "label-456")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
