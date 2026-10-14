@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixPlanTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newSkillMixPlan("code-194", label: "label-598")
        #expect(item.status == Staffing.SkillMixPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newSkillMixPlan("code-194", label: "label-598")
        try item.moveTo(Staffing.SkillMixPlanStatus.withdrawn)
        #expect(item.status == Staffing.SkillMixPlanStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newSkillMixPlan("code-194", label: "label-598")
        item.status = Staffing.SkillMixPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixPlanStatus.proposed) }
    }
}
