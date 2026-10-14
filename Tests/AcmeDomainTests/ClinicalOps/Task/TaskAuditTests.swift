@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAuditTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newTaskAudit("code-838", label: "label-548")
        #expect(item.status == ClinicalOps.TaskAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newTaskAudit("code-838", label: "label-548")
        try item.moveTo(ClinicalOps.TaskAuditStatus.approved)
        #expect(item.status == ClinicalOps.TaskAuditStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newTaskAudit("code-838", label: "label-548")
        item.status = ClinicalOps.TaskAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskAuditStatus.proposed) }
    }
}
