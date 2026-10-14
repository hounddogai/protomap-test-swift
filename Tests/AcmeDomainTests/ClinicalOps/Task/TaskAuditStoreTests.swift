@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskAuditStore = ClinicalOps.newMemoryTaskAuditStore()
        let item = ClinicalOps.newTaskAudit("code-838", label: "label-548")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
