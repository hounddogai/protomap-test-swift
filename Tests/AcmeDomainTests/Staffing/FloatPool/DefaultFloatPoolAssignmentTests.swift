@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultFloatPoolAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newDefaultFloatPoolAssignment("code-200", name: "name-100")
        #expect(item.status == Staffing.DefaultFloatPoolAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newDefaultFloatPoolAssignment("code-200", name: "name-100")
        try item.moveTo(Staffing.DefaultFloatPoolAssignmentStatus.approved)
        #expect(item.status == Staffing.DefaultFloatPoolAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newDefaultFloatPoolAssignment("code-200", name: "name-100")
        item.status = Staffing.DefaultFloatPoolAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultFloatPoolAssignmentStatus.proposed) }
    }
}
