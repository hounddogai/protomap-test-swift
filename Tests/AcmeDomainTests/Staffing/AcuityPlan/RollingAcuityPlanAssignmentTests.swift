@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingAcuityPlanAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newRollingAcuityPlanAssignment("code-918", name: "name-634")
        #expect(item.status == Staffing.RollingAcuityPlanAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newRollingAcuityPlanAssignment("code-918", name: "name-634")
        try item.moveTo(Staffing.RollingAcuityPlanAssignmentStatus.inProgress)
        #expect(item.status == Staffing.RollingAcuityPlanAssignmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newRollingAcuityPlanAssignment("code-918", name: "name-634")
        item.status = Staffing.RollingAcuityPlanAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingAcuityPlanAssignmentStatus.planned) }
    }
}
