@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixPlanTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newSeasonalSkillMixPlan("code-319", label: "label-564")
        #expect(item.status == Staffing.SeasonalSkillMixPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newSeasonalSkillMixPlan("code-319", label: "label-564")
        try item.moveTo(Staffing.SeasonalSkillMixPlanStatus.revoked)
        #expect(item.status == Staffing.SeasonalSkillMixPlanStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newSeasonalSkillMixPlan("code-319", label: "label-564")
        item.status = Staffing.SeasonalSkillMixPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalSkillMixPlanStatus.requested) }
    }
}
