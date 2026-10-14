@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffAuditTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newHandoffAudit("code-278", label: "label-798")
        #expect(item.status == ClinicalOps.HandoffAuditStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newHandoffAudit("code-278", label: "label-798")
        try item.moveTo(ClinicalOps.HandoffAuditStatus.cancelled)
        #expect(item.status == ClinicalOps.HandoffAuditStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newHandoffAudit("code-278", label: "label-798")
        item.status = ClinicalOps.HandoffAuditStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffAuditStatus.planned) }
    }
}
