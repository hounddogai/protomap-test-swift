@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAllocationTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newAlertAllocation("code-224", label: "label-393")
        #expect(item.status == ClinicalOps.AlertAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newAlertAllocation("code-224", label: "label-393")
        try item.moveTo(ClinicalOps.AlertAllocationStatus.queued)
        #expect(item.status == ClinicalOps.AlertAllocationStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newAlertAllocation("code-224", label: "label-393")
        item.status = ClinicalOps.AlertAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertAllocationStatus.new) }
    }
}
