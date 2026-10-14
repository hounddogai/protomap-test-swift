@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingFloatPoolAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newRollingFloatPoolAssignment("code-468", label: "label-796")
        #expect(item.status == Staffing.RollingFloatPoolAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newRollingFloatPoolAssignment("code-468", label: "label-796")
        try item.moveTo(Staffing.RollingFloatPoolAssignmentStatus.rejected)
        #expect(item.status == Staffing.RollingFloatPoolAssignmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newRollingFloatPoolAssignment("code-468", label: "label-796")
        item.status = Staffing.RollingFloatPoolAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingFloatPoolAssignmentStatus.proposed) }
    }
}
