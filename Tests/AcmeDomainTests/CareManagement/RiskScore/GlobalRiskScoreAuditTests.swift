@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalRiskScoreAuditTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newGlobalRiskScoreAudit("code-237", name: "name-721")
        #expect(item.status == CareManagement.GlobalRiskScoreAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newGlobalRiskScoreAudit("code-237", name: "name-721")
        try item.moveTo(CareManagement.GlobalRiskScoreAuditStatus.failed)
        #expect(item.status == CareManagement.GlobalRiskScoreAuditStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newGlobalRiskScoreAudit("code-237", name: "name-721")
        item.status = CareManagement.GlobalRiskScoreAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalRiskScoreAuditStatus.new) }
    }
}
