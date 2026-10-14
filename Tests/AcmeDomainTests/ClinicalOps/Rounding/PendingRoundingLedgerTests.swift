@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingRoundingLedgerTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newPendingRoundingLedger("code-84", name: "name-453")
        #expect(item.status == ClinicalOps.PendingRoundingLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newPendingRoundingLedger("code-84", name: "name-453")
        try item.moveTo(ClinicalOps.PendingRoundingLedgerStatus.resolved)
        #expect(item.status == ClinicalOps.PendingRoundingLedgerStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newPendingRoundingLedger("code-84", name: "name-453")
        item.status = ClinicalOps.PendingRoundingLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingRoundingLedgerStatus.`open`) }
    }
}
