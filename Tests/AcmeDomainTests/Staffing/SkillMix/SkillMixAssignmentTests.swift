@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixAssignmentTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newSkillMixAssignment("code-888", name: "name-922")
        #expect(item.status == Staffing.SkillMixAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Staffing.newSkillMixAssignment("code-888", name: "name-922")
        try item.moveTo(Staffing.SkillMixAssignmentStatus.retired)
        #expect(item.status == Staffing.SkillMixAssignmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newSkillMixAssignment("code-888", name: "name-922")
        item.status = Staffing.SkillMixAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixAssignmentStatus.created) }
    }
}
