@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredHandoffLedgerTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newTieredHandoffLedger("code-43", name: "name-90")
        #expect(item.status == ClinicalOps.TieredHandoffLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newTieredHandoffLedger("code-43", name: "name-90")
        try item.moveTo(ClinicalOps.TieredHandoffLedgerStatus.pending)
        #expect(item.status == ClinicalOps.TieredHandoffLedgerStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newTieredHandoffLedger("code-43", name: "name-90")
        item.status = ClinicalOps.TieredHandoffLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredHandoffLedgerStatus.draft) }
    }
}
