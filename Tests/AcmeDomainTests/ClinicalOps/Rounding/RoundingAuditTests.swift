@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingAuditTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newRoundingAudit("code-825", name: "name-394")
        #expect(item.status == ClinicalOps.RoundingAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newRoundingAudit("code-825", name: "name-394")
        try item.moveTo(ClinicalOps.RoundingAuditStatus.done)
        #expect(item.status == ClinicalOps.RoundingAuditStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newRoundingAudit("code-825", name: "name-394")
        item.status = ClinicalOps.RoundingAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingAuditStatus.new) }
    }
}
