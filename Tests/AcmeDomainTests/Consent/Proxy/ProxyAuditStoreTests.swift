@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyAuditStore = Consent.newMemoryProxyAuditStore()
        let item = Consent.newProxyAudit("code-870", title: "title-510")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
