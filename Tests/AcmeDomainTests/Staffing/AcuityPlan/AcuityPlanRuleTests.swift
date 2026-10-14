@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRuleTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newAcuityPlanRule("code-293", name: "name-784")
        #expect(item.status == Staffing.AcuityPlanRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newAcuityPlanRule("code-293", name: "name-784")
        try item.moveTo(Staffing.AcuityPlanRuleStatus.expired)
        #expect(item.status == Staffing.AcuityPlanRuleStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newAcuityPlanRule("code-293", name: "name-784")
        item.status = Staffing.AcuityPlanRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanRuleStatus.requested) }
    }
}
