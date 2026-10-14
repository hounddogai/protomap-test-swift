@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceAuditStore = RevenueCycle.newMemoryRemittanceAuditStore()
        let item = RevenueCycle.newRemittanceAudit("code-469", label: "label-349")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
