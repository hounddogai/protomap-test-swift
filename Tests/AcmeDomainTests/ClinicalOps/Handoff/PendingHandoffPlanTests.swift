@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingHandoffPlanTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newPendingHandoffPlan("code-221", label: "label-371")
        #expect(item.status == ClinicalOps.PendingHandoffPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newPendingHandoffPlan("code-221", label: "label-371")
        try item.moveTo(ClinicalOps.PendingHandoffPlanStatus.active)
        #expect(item.status == ClinicalOps.PendingHandoffPlanStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newPendingHandoffPlan("code-221", label: "label-371")
        item.status = ClinicalOps.PendingHandoffPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingHandoffPlanStatus.draft) }
    }
}
