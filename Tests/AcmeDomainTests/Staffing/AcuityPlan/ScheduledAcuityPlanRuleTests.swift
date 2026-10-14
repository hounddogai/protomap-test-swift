@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanRuleTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newScheduledAcuityPlanRule("code-973", label: "label-739")
        #expect(item.status == Staffing.ScheduledAcuityPlanRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newScheduledAcuityPlanRule("code-973", label: "label-739")
        try item.moveTo(Staffing.ScheduledAcuityPlanRuleStatus.reopened)
        #expect(item.status == Staffing.ScheduledAcuityPlanRuleStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newScheduledAcuityPlanRule("code-973", label: "label-739")
        item.status = Staffing.ScheduledAcuityPlanRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledAcuityPlanRuleStatus.`open`) }
    }
}
