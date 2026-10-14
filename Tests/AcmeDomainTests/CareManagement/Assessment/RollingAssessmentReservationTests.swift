@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentReservationTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newRollingAssessmentReservation("code-70", name: "name-440")
        #expect(item.status == CareManagement.RollingAssessmentReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newRollingAssessmentReservation("code-70", name: "name-440")
        try item.moveTo(CareManagement.RollingAssessmentReservationStatus.approved)
        #expect(item.status == CareManagement.RollingAssessmentReservationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newRollingAssessmentReservation("code-70", name: "name-440")
        item.status = CareManagement.RollingAssessmentReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingAssessmentReservationStatus.proposed) }
    }
}
