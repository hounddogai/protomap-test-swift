@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationReviewTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newAdaptiveIsolationReview("code-264", title: "title-556")
        #expect(item.status == BedManagement.AdaptiveIsolationReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = BedManagement.newAdaptiveIsolationReview("code-264", title: "title-556")
        try item.moveTo(BedManagement.AdaptiveIsolationReviewStatus.closed)
        #expect(item.status == BedManagement.AdaptiveIsolationReviewStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newAdaptiveIsolationReview("code-264", title: "title-556")
        item.status = BedManagement.AdaptiveIsolationReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveIsolationReviewStatus.draft) }
    }
}
