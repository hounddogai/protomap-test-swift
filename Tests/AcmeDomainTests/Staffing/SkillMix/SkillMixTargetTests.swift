@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixTargetTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newSkillMixTarget("code-573", name: "name-755")
        #expect(item.status == Staffing.SkillMixTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newSkillMixTarget("code-573", name: "name-755")
        try item.moveTo(Staffing.SkillMixTargetStatus.completed)
        #expect(item.status == Staffing.SkillMixTargetStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newSkillMixTarget("code-573", name: "name-755")
        item.status = Staffing.SkillMixTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixTargetStatus.planned) }
    }
}
