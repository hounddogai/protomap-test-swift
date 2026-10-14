@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolReviewTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newFloatPoolReview("code-2", title: "title-463")
        #expect(item.status == Staffing.FloatPoolReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newFloatPoolReview("code-2", title: "title-463")
        try item.moveTo(Staffing.FloatPoolReviewStatus.approved)
        #expect(item.status == Staffing.FloatPoolReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newFloatPoolReview("code-2", title: "title-463")
        item.status = Staffing.FloatPoolReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolReviewStatus.proposed) }
    }
}
