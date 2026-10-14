@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLenientOrderSetAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LenientOrderSetAuditStore = ClinicalOps.newMemoryLenientOrderSetAuditStore()
        let item = ClinicalOps.newLenientOrderSetAudit("code-105", name: "name-4")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
