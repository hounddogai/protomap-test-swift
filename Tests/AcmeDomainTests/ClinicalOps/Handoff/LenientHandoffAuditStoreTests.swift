@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLenientHandoffAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LenientHandoffAuditStore = ClinicalOps.newMemoryLenientHandoffAuditStore()
        let item = ClinicalOps.newLenientHandoffAudit("code-129", title: "title-582")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
