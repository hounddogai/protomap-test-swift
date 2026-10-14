@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertTargetTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newAlertTarget("code-886", label: "label-242")
        #expect(item.status == ClinicalOps.AlertTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newAlertTarget("code-886", label: "label-242")
        try item.moveTo(ClinicalOps.AlertTargetStatus.suspended)
        #expect(item.status == ClinicalOps.AlertTargetStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newAlertTarget("code-886", label: "label-242")
        item.status = ClinicalOps.AlertTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertTargetStatus.draft) }
    }
}
