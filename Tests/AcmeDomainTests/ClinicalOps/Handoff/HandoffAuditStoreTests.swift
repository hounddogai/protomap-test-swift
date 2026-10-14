@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffAuditStore = ClinicalOps.newMemoryHandoffAuditStore()
        let item = ClinicalOps.newHandoffAudit("code-278", label: "label-798")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
