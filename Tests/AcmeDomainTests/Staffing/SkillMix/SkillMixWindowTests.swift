@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixWindowTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newSkillMixWindow("code-963", title: "title-468")
        #expect(item.status == Staffing.SkillMixWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newSkillMixWindow("code-963", title: "title-468")
        try item.moveTo(Staffing.SkillMixWindowStatus.inProgress)
        #expect(item.status == Staffing.SkillMixWindowStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newSkillMixWindow("code-963", title: "title-468")
        item.status = Staffing.SkillMixWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixWindowStatus.planned) }
    }
}
