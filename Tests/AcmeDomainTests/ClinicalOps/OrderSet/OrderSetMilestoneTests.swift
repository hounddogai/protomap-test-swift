@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetMilestoneTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newOrderSetMilestone("code-695", label: "label-179")
        #expect(item.status == ClinicalOps.OrderSetMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newOrderSetMilestone("code-695", label: "label-179")
        try item.moveTo(ClinicalOps.OrderSetMilestoneStatus.pending)
        #expect(item.status == ClinicalOps.OrderSetMilestoneStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newOrderSetMilestone("code-695", label: "label-179")
        item.status = ClinicalOps.OrderSetMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetMilestoneStatus.draft) }
    }
}
