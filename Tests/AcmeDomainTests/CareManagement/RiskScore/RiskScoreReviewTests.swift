@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreReviewTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRiskScoreReview("code-394", name: "name-144")
        #expect(item.status == CareManagement.RiskScoreReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newRiskScoreReview("code-394", name: "name-144")
        try item.moveTo(CareManagement.RiskScoreReviewStatus.pending)
        #expect(item.status == CareManagement.RiskScoreReviewStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRiskScoreReview("code-394", name: "name-144")
        item.status = CareManagement.RiskScoreReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreReviewStatus.draft) }
    }
}
