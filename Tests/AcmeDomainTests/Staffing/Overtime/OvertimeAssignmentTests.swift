@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAssignmentTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newOvertimeAssignment("code-858", name: "name-595")
        #expect(item.status == Staffing.OvertimeAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newOvertimeAssignment("code-858", name: "name-595")
        try item.moveTo(Staffing.OvertimeAssignmentStatus.inReview)
        #expect(item.status == Staffing.OvertimeAssignmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newOvertimeAssignment("code-858", name: "name-595")
        item.status = Staffing.OvertimeAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeAssignmentStatus.`open`) }
    }
}
