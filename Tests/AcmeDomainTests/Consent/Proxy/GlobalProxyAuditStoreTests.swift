@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryGlobalProxyAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.GlobalProxyAuditStore = Consent.newMemoryGlobalProxyAuditStore()
        let item = Consent.newGlobalProxyAudit("code-45", title: "title-226")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
