@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanAssignmentTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newAcuityPlanAssignment("code-342", label: "label-485")
        #expect(item.status == Staffing.AcuityPlanAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newAcuityPlanAssignment("code-342", label: "label-485")
        try item.moveTo(Staffing.AcuityPlanAssignmentStatus.granted)
        #expect(item.status == Staffing.AcuityPlanAssignmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newAcuityPlanAssignment("code-342", label: "label-485")
        item.status = Staffing.AcuityPlanAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanAssignmentStatus.requested) }
    }
}
