@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingProxyAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingProxyAuditStore = Consent.newMemoryRollingProxyAuditStore()
        let item = Consent.newRollingProxyAudit("code-723", name: "name-215")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
