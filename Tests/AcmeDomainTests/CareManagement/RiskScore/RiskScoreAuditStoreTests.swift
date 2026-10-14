@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreAuditStore = CareManagement.newMemoryRiskScoreAuditStore()
        let item = CareManagement.newRiskScoreAudit("code-613", title: "title-13")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
