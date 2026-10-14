@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedAcuityPlanAssignmentTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newCappedAcuityPlanAssignment("code-163", title: "title-325")
        #expect(item.status == Staffing.CappedAcuityPlanAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newCappedAcuityPlanAssignment("code-163", title: "title-325")
        try item.moveTo(Staffing.CappedAcuityPlanAssignmentStatus.granted)
        #expect(item.status == Staffing.CappedAcuityPlanAssignmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newCappedAcuityPlanAssignment("code-163", title: "title-325")
        item.status = Staffing.CappedAcuityPlanAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedAcuityPlanAssignmentStatus.requested) }
    }
}
