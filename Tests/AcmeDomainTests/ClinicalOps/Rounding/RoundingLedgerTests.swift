@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingLedgerTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newRoundingLedger("code-271", label: "label-307")
        #expect(item.status == ClinicalOps.RoundingLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newRoundingLedger("code-271", label: "label-307")
        try item.moveTo(ClinicalOps.RoundingLedgerStatus.revoked)
        #expect(item.status == ClinicalOps.RoundingLedgerStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newRoundingLedger("code-271", label: "label-307")
        item.status = ClinicalOps.RoundingLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingLedgerStatus.requested) }
    }
}
