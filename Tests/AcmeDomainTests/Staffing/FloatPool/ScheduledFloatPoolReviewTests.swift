@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolReviewTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newScheduledFloatPoolReview("code-108", title: "title-694")
        #expect(item.status == Staffing.ScheduledFloatPoolReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newScheduledFloatPoolReview("code-108", title: "title-694")
        try item.moveTo(Staffing.ScheduledFloatPoolReviewStatus.pending)
        #expect(item.status == Staffing.ScheduledFloatPoolReviewStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newScheduledFloatPoolReview("code-108", title: "title-694")
        item.status = Staffing.ScheduledFloatPoolReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledFloatPoolReviewStatus.draft) }
    }
}
