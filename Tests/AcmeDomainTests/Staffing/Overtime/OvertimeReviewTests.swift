@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeReviewTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newOvertimeReview("code-163", name: "name-780")
        #expect(item.status == Staffing.OvertimeReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newOvertimeReview("code-163", name: "name-780")
        try item.moveTo(Staffing.OvertimeReviewStatus.pending)
        #expect(item.status == Staffing.OvertimeReviewStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newOvertimeReview("code-163", name: "name-780")
        item.status = Staffing.OvertimeReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeReviewStatus.draft) }
    }
}
