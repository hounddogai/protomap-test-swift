@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixCycleTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSkillMixCycle("code-433", label: "label-617")
        #expect(item.status == Staffing.SkillMixCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newSkillMixCycle("code-433", label: "label-617")
        try item.moveTo(Staffing.SkillMixCycleStatus.active)
        #expect(item.status == Staffing.SkillMixCycleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSkillMixCycle("code-433", label: "label-617")
        item.status = Staffing.SkillMixCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixCycleStatus.draft) }
    }
}
