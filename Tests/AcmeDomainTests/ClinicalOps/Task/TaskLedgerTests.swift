@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskLedgerTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newTaskLedger("code-102", label: "label-155")
        #expect(item.status == ClinicalOps.TaskLedgerStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newTaskLedger("code-102", label: "label-155")
        try item.moveTo(ClinicalOps.TaskLedgerStatus.completed)
        #expect(item.status == ClinicalOps.TaskLedgerStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newTaskLedger("code-102", label: "label-155")
        item.status = ClinicalOps.TaskLedgerStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskLedgerStatus.planned) }
    }
}
