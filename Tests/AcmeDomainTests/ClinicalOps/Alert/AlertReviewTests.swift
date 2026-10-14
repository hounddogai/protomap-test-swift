@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertReviewTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAlertReview("code-790", label: "label-799")
        #expect(item.status == ClinicalOps.AlertReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newAlertReview("code-790", label: "label-799")
        try item.moveTo(ClinicalOps.AlertReviewStatus.approved)
        #expect(item.status == ClinicalOps.AlertReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAlertReview("code-790", label: "label-799")
        item.status = ClinicalOps.AlertReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertReviewStatus.proposed) }
    }
}
