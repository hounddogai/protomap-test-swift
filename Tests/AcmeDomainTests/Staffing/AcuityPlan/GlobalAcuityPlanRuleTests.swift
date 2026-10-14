@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalAcuityPlanRuleTests {
    @Test func startsInNew() throws {
        let item = Staffing.newGlobalAcuityPlanRule("code-838", title: "title-776")
        #expect(item.status == Staffing.GlobalAcuityPlanRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newGlobalAcuityPlanRule("code-838", title: "title-776")
        try item.moveTo(Staffing.GlobalAcuityPlanRuleStatus.queued)
        #expect(item.status == Staffing.GlobalAcuityPlanRuleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newGlobalAcuityPlanRule("code-838", title: "title-776")
        item.status = Staffing.GlobalAcuityPlanRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalAcuityPlanRuleStatus.new) }
    }
}
