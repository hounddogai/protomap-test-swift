@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixOverrideTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newSkillMixOverride("code-940", title: "title-241")
        #expect(item.status == Staffing.SkillMixOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newSkillMixOverride("code-940", title: "title-241")
        try item.moveTo(Staffing.SkillMixOverrideStatus.completed)
        #expect(item.status == Staffing.SkillMixOverrideStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newSkillMixOverride("code-940", title: "title-241")
        item.status = Staffing.SkillMixOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixOverrideStatus.planned) }
    }
}
