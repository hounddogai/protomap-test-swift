@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualRiskScoreAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualRiskScoreAuditStore = CareManagement.newMemoryManualRiskScoreAuditStore()
        let item = CareManagement.newManualRiskScoreAudit("code-429", title: "title-12")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
