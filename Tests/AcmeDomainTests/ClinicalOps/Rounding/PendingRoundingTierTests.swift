@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingRoundingTierTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newPendingRoundingTier("code-250", label: "label-77")
        #expect(item.status == ClinicalOps.PendingRoundingTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newPendingRoundingTier("code-250", label: "label-77")
        try item.moveTo(ClinicalOps.PendingRoundingTierStatus.inReview)
        #expect(item.status == ClinicalOps.PendingRoundingTierStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newPendingRoundingTier("code-250", label: "label-77")
        item.status = ClinicalOps.PendingRoundingTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingRoundingTierStatus.`open`) }
    }
}
