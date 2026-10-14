@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingSkillMixScheduleTests {
    @Test func startsInNew() throws {
        let item = Staffing.newRollingSkillMixSchedule("code-157", name: "name-230")
        #expect(item.status == Staffing.RollingSkillMixScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newRollingSkillMixSchedule("code-157", name: "name-230")
        try item.moveTo(Staffing.RollingSkillMixScheduleStatus.queued)
        #expect(item.status == Staffing.RollingSkillMixScheduleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newRollingSkillMixSchedule("code-157", name: "name-230")
        item.status = Staffing.RollingSkillMixScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingSkillMixScheduleStatus.new) }
    }
}
