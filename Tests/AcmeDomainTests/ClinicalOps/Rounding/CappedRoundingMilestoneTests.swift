@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedRoundingMilestoneTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newCappedRoundingMilestone("code-955", label: "label-174")
        #expect(item.status == ClinicalOps.CappedRoundingMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newCappedRoundingMilestone("code-955", label: "label-174")
        try item.moveTo(ClinicalOps.CappedRoundingMilestoneStatus.active)
        #expect(item.status == ClinicalOps.CappedRoundingMilestoneStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newCappedRoundingMilestone("code-955", label: "label-174")
        item.status = ClinicalOps.CappedRoundingMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedRoundingMilestoneStatus.draft) }
    }
}
