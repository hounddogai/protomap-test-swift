@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertAuditStore = ClinicalOps.newMemoryAlertAuditStore()
        let item = ClinicalOps.newAlertAudit("code-791", label: "label-362")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
