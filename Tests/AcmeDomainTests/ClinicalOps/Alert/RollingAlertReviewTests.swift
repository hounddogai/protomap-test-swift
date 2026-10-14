@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertReviewTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newRollingAlertReview("code-568", name: "name-540")
        #expect(item.status == ClinicalOps.RollingAlertReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newRollingAlertReview("code-568", name: "name-540")
        try item.moveTo(ClinicalOps.RollingAlertReviewStatus.approved)
        #expect(item.status == ClinicalOps.RollingAlertReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newRollingAlertReview("code-568", name: "name-540")
        item.status = ClinicalOps.RollingAlertReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingAlertReviewStatus.proposed) }
    }
}
