@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixRuleTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newSkillMixRule("code-998", name: "name-735")
        #expect(item.status == Staffing.SkillMixRuleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newSkillMixRule("code-998", name: "name-735")
        try item.moveTo(Staffing.SkillMixRuleStatus.scheduled)
        #expect(item.status == Staffing.SkillMixRuleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newSkillMixRule("code-998", name: "name-735")
        item.status = Staffing.SkillMixRuleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixRuleStatus.planned) }
    }
}
