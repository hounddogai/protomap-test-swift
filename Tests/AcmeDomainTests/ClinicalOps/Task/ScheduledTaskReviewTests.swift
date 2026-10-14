@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledTaskReviewTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newScheduledTaskReview("code-487", label: "label-921")
        #expect(item.status == ClinicalOps.ScheduledTaskReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newScheduledTaskReview("code-487", label: "label-921")
        try item.moveTo(ClinicalOps.ScheduledTaskReviewStatus.done)
        #expect(item.status == ClinicalOps.ScheduledTaskReviewStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newScheduledTaskReview("code-487", label: "label-921")
        item.status = ClinicalOps.ScheduledTaskReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledTaskReviewStatus.new) }
    }
}
