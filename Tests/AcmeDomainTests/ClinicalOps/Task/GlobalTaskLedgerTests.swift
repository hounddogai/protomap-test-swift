@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskLedgerTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newGlobalTaskLedger("code-335", title: "title-42")
        #expect(item.status == ClinicalOps.GlobalTaskLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newGlobalTaskLedger("code-335", title: "title-42")
        try item.moveTo(ClinicalOps.GlobalTaskLedgerStatus.retired)
        #expect(item.status == ClinicalOps.GlobalTaskLedgerStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newGlobalTaskLedger("code-335", title: "title-42")
        item.status = ClinicalOps.GlobalTaskLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalTaskLedgerStatus.created) }
    }
}
