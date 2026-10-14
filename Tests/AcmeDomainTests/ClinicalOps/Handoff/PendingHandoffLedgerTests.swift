@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingHandoffLedgerTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newPendingHandoffLedger("code-906", title: "title-873")
        #expect(item.status == ClinicalOps.PendingHandoffLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newPendingHandoffLedger("code-906", title: "title-873")
        try item.moveTo(ClinicalOps.PendingHandoffLedgerStatus.granted)
        #expect(item.status == ClinicalOps.PendingHandoffLedgerStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newPendingHandoffLedger("code-906", title: "title-873")
        item.status = ClinicalOps.PendingHandoffLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingHandoffLedgerStatus.requested) }
    }
}
