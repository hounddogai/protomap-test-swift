@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualSkillMixScheduleTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newManualSkillMixSchedule("code-898", label: "label-643")
        #expect(item.status == Staffing.ManualSkillMixScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Staffing.newManualSkillMixSchedule("code-898", label: "label-643")
        try item.moveTo(Staffing.ManualSkillMixScheduleStatus.cancelled)
        #expect(item.status == Staffing.ManualSkillMixScheduleStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newManualSkillMixSchedule("code-898", label: "label-643")
        item.status = Staffing.ManualSkillMixScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualSkillMixScheduleStatus.planned) }
    }
}
