@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskReviewTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newTaskReview("code-801", name: "name-295")
        #expect(item.status == ClinicalOps.TaskReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = ClinicalOps.newTaskReview("code-801", name: "name-295")
        try item.moveTo(ClinicalOps.TaskReviewStatus.stopped)
        #expect(item.status == ClinicalOps.TaskReviewStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newTaskReview("code-801", name: "name-295")
        item.status = ClinicalOps.TaskReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskReviewStatus.idle) }
    }
}
