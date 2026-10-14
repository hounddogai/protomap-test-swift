@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientSkillMixAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newLenientSkillMixAssignment("code-63", title: "title-469")
        #expect(item.status == Staffing.LenientSkillMixAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newLenientSkillMixAssignment("code-63", title: "title-469")
        try item.moveTo(Staffing.LenientSkillMixAssignmentStatus.warming)
        #expect(item.status == Staffing.LenientSkillMixAssignmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newLenientSkillMixAssignment("code-63", title: "title-469")
        item.status = Staffing.LenientSkillMixAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientSkillMixAssignmentStatus.idle) }
    }
}
