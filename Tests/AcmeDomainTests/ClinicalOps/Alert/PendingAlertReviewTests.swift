@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingAlertReviewTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newPendingAlertReview("code-480", label: "label-792")
        #expect(item.status == ClinicalOps.PendingAlertReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newPendingAlertReview("code-480", label: "label-792")
        try item.moveTo(ClinicalOps.PendingAlertReviewStatus.resolved)
        #expect(item.status == ClinicalOps.PendingAlertReviewStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newPendingAlertReview("code-480", label: "label-792")
        item.status = ClinicalOps.PendingAlertReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingAlertReviewStatus.`open`) }
    }
}
