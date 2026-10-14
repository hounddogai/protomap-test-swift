@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryCappedRemittanceAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.CappedRemittanceAuditStore = RevenueCycle.newMemoryCappedRemittanceAuditStore()
        let item = RevenueCycle.newCappedRemittanceAudit("code-881", label: "label-519")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
