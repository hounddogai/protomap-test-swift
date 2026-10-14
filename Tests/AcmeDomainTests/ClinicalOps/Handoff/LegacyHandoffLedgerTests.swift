@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyHandoffLedgerTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newLegacyHandoffLedger("code-507", label: "label-692")
        #expect(item.status == ClinicalOps.LegacyHandoffLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newLegacyHandoffLedger("code-507", label: "label-692")
        try item.moveTo(ClinicalOps.LegacyHandoffLedgerStatus.queued)
        #expect(item.status == ClinicalOps.LegacyHandoffLedgerStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newLegacyHandoffLedger("code-507", label: "label-692")
        item.status = ClinicalOps.LegacyHandoffLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyHandoffLedgerStatus.new) }
    }
}
