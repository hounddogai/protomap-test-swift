@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledRiskScoreAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledRiskScoreAuditStore = CareManagement.newMemoryScheduledRiskScoreAuditStore()
        let item = CareManagement.newScheduledRiskScoreAudit("code-877", title: "title-974")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
