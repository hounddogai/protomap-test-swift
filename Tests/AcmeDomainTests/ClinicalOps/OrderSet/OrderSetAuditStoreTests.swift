@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetAuditStore = ClinicalOps.newMemoryOrderSetAuditStore()
        let item = ClinicalOps.newOrderSetAudit("code-577", name: "name-351")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
