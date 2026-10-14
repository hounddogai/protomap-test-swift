@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreAuditTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newScheduledRiskScoreAudit("code-877", title: "title-974")
        #expect(item.status == CareManagement.ScheduledRiskScoreAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newScheduledRiskScoreAudit("code-877", title: "title-974")
        try item.moveTo(CareManagement.ScheduledRiskScoreAuditStatus.validated)
        #expect(item.status == CareManagement.ScheduledRiskScoreAuditStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newScheduledRiskScoreAudit("code-877", title: "title-974")
        item.status = CareManagement.ScheduledRiskScoreAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledRiskScoreAuditStatus.created) }
    }
}
