@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAdjustmentTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTaskAdjustment("code-521", label: "label-98")
        #expect(item.status == ClinicalOps.TaskAdjustmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newTaskAdjustment("code-521", label: "label-98")
        try item.moveTo(ClinicalOps.TaskAdjustmentStatus.queued)
        #expect(item.status == ClinicalOps.TaskAdjustmentStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTaskAdjustment("code-521", label: "label-98")
        item.status = ClinicalOps.TaskAdjustmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskAdjustmentStatus.new) }
    }
}
