@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledCareGapReviewTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newScheduledCareGapReview("code-241", label: "label-605")
        #expect(item.status == CareManagement.ScheduledCareGapReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = CareManagement.newScheduledCareGapReview("code-241", label: "label-605")
        try item.moveTo(CareManagement.ScheduledCareGapReviewStatus.stopped)
        #expect(item.status == CareManagement.ScheduledCareGapReviewStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newScheduledCareGapReview("code-241", label: "label-605")
        item.status = CareManagement.ScheduledCareGapReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledCareGapReviewStatus.idle) }
    }
}
