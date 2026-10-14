@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreAuditTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newRiskScoreAudit("code-613", title: "title-13")
        #expect(item.status == CareManagement.RiskScoreAuditStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = CareManagement.newRiskScoreAudit("code-613", title: "title-13")
        try item.moveTo(CareManagement.RiskScoreAuditStatus.stopped)
        #expect(item.status == CareManagement.RiskScoreAuditStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newRiskScoreAudit("code-613", title: "title-13")
        item.status = CareManagement.RiskScoreAuditStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreAuditStatus.idle) }
    }
}
