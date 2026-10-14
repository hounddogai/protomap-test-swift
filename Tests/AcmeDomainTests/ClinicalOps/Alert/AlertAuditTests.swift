@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAuditTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newAlertAudit("code-791", label: "label-362")
        #expect(item.status == ClinicalOps.AlertAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newAlertAudit("code-791", label: "label-362")
        try item.moveTo(ClinicalOps.AlertAuditStatus.revoked)
        #expect(item.status == ClinicalOps.AlertAuditStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newAlertAudit("code-791", label: "label-362")
        item.status = ClinicalOps.AlertAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertAuditStatus.requested) }
    }
}
