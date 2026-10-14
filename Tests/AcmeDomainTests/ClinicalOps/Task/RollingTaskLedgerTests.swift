@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingTaskLedgerTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newRollingTaskLedger("code-775", title: "title-38")
        #expect(item.status == ClinicalOps.RollingTaskLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newRollingTaskLedger("code-775", title: "title-38")
        try item.moveTo(ClinicalOps.RollingTaskLedgerStatus.failed)
        #expect(item.status == ClinicalOps.RollingTaskLedgerStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newRollingTaskLedger("code-775", title: "title-38")
        item.status = ClinicalOps.RollingTaskLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingTaskLedgerStatus.new) }
    }
}
