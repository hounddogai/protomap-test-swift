@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeReviewTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newScheduledOvertimeReview("code-46", title: "title-254")
        #expect(item.status == Staffing.ScheduledOvertimeReviewStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newScheduledOvertimeReview("code-46", title: "title-254")
        try item.moveTo(Staffing.ScheduledOvertimeReviewStatus.inProgress)
        #expect(item.status == Staffing.ScheduledOvertimeReviewStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newScheduledOvertimeReview("code-46", title: "title-254")
        item.status = Staffing.ScheduledOvertimeReviewStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledOvertimeReviewStatus.planned) }
    }
}
