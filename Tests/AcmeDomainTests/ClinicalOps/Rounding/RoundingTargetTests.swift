@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingTargetTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newRoundingTarget("code-218", label: "label-142")
        #expect(item.status == ClinicalOps.RoundingTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newRoundingTarget("code-218", label: "label-142")
        try item.moveTo(ClinicalOps.RoundingTargetStatus.inReview)
        #expect(item.status == ClinicalOps.RoundingTargetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newRoundingTarget("code-218", label: "label-142")
        item.status = ClinicalOps.RoundingTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingTargetStatus.`open`) }
    }
}
