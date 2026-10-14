@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultSkillMixAssignmentTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newDefaultSkillMixAssignment("code-550", name: "name-80")
        #expect(item.status == Staffing.DefaultSkillMixAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newDefaultSkillMixAssignment("code-550", name: "name-80")
        try item.moveTo(Staffing.DefaultSkillMixAssignmentStatus.suspended)
        #expect(item.status == Staffing.DefaultSkillMixAssignmentStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newDefaultSkillMixAssignment("code-550", name: "name-80")
        item.status = Staffing.DefaultSkillMixAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultSkillMixAssignmentStatus.draft) }
    }
}
