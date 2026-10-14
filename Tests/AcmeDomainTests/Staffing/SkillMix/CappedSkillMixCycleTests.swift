@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixCycleTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newCappedSkillMixCycle("code-602", title: "title-839")
        #expect(item.status == Staffing.CappedSkillMixCycleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newCappedSkillMixCycle("code-602", title: "title-839")
        try item.moveTo(Staffing.CappedSkillMixCycleStatus.ready)
        #expect(item.status == Staffing.CappedSkillMixCycleStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newCappedSkillMixCycle("code-602", title: "title-839")
        item.status = Staffing.CappedSkillMixCycleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedSkillMixCycleStatus.idle) }
    }
}
