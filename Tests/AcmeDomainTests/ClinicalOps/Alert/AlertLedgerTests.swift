@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertLedgerTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAlertLedger("code-112", name: "name-941")
        #expect(item.status == ClinicalOps.AlertLedgerStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newAlertLedger("code-112", name: "name-941")
        try item.moveTo(ClinicalOps.AlertLedgerStatus.withdrawn)
        #expect(item.status == ClinicalOps.AlertLedgerStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAlertLedger("code-112", name: "name-941")
        item.status = ClinicalOps.AlertLedgerStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertLedgerStatus.proposed) }
    }
}
