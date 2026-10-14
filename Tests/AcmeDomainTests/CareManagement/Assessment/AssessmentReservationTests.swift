@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentReservationTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newAssessmentReservation("code-193", name: "name-195")
        #expect(item.status == CareManagement.AssessmentReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newAssessmentReservation("code-193", name: "name-195")
        try item.moveTo(CareManagement.AssessmentReservationStatus.inReview)
        #expect(item.status == CareManagement.AssessmentReservationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newAssessmentReservation("code-193", name: "name-195")
        item.status = CareManagement.AssessmentReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentReservationStatus.`open`) }
    }
}
