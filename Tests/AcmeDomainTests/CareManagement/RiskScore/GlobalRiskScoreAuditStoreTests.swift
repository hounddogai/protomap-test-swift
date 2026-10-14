@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalRiskScoreAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalRiskScoreAuditStore = CareManagement.newMemoryGlobalRiskScoreAuditStore()
        let item = CareManagement.newGlobalRiskScoreAudit("code-237", name: "name-721")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
