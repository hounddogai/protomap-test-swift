@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingAlertLedgerTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newPendingAlertLedger("code-12", title: "title-394")
        #expect(item.status == ClinicalOps.PendingAlertLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newPendingAlertLedger("code-12", title: "title-394")
        try item.moveTo(ClinicalOps.PendingAlertLedgerStatus.queued)
        #expect(item.status == ClinicalOps.PendingAlertLedgerStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newPendingAlertLedger("code-12", title: "title-394")
        item.status = ClinicalOps.PendingAlertLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingAlertLedgerStatus.new) }
    }
}
