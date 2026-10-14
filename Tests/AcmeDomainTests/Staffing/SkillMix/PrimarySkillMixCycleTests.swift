@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixCycleTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newPrimarySkillMixCycle("code-375", name: "name-567")
        #expect(item.status == Staffing.PrimarySkillMixCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newPrimarySkillMixCycle("code-375", name: "name-567")
        try item.moveTo(Staffing.PrimarySkillMixCycleStatus.active)
        #expect(item.status == Staffing.PrimarySkillMixCycleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newPrimarySkillMixCycle("code-375", name: "name-567")
        item.status = Staffing.PrimarySkillMixCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimarySkillMixCycleStatus.draft) }
    }
}
