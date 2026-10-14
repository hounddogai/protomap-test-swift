@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetReviewTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newOrderSetReview("code-665", label: "label-866")
        #expect(item.status == ClinicalOps.OrderSetReviewStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newOrderSetReview("code-665", label: "label-866")
        try item.moveTo(ClinicalOps.OrderSetReviewStatus.completed)
        #expect(item.status == ClinicalOps.OrderSetReviewStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newOrderSetReview("code-665", label: "label-866")
        item.status = ClinicalOps.OrderSetReviewStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetReviewStatus.planned) }
    }
}
