@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanReviewTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAcuityPlanReview("code-138", name: "name-152")
        #expect(item.status == Staffing.AcuityPlanReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newAcuityPlanReview("code-138", name: "name-152")
        try item.moveTo(Staffing.AcuityPlanReviewStatus.withdrawn)
        #expect(item.status == Staffing.AcuityPlanReviewStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAcuityPlanReview("code-138", name: "name-152")
        item.status = Staffing.AcuityPlanReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanReviewStatus.proposed) }
    }
}
