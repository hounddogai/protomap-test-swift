@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientOrderSetAuditTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newLenientOrderSetAudit("code-105", name: "name-4")
        #expect(item.status == ClinicalOps.LenientOrderSetAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newLenientOrderSetAudit("code-105", name: "name-4")
        try item.moveTo(ClinicalOps.LenientOrderSetAuditStatus.suspended)
        #expect(item.status == ClinicalOps.LenientOrderSetAuditStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newLenientOrderSetAudit("code-105", name: "name-4")
        item.status = ClinicalOps.LenientOrderSetAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientOrderSetAuditStatus.draft) }
    }
}
