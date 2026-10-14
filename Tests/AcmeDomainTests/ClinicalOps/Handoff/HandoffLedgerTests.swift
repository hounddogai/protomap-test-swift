@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffLedgerTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newHandoffLedger("code-367", title: "title-487")
        #expect(item.status == ClinicalOps.HandoffLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newHandoffLedger("code-367", title: "title-487")
        try item.moveTo(ClinicalOps.HandoffLedgerStatus.queued)
        #expect(item.status == ClinicalOps.HandoffLedgerStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newHandoffLedger("code-367", title: "title-487")
        item.status = ClinicalOps.HandoffLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffLedgerStatus.new) }
    }
}
