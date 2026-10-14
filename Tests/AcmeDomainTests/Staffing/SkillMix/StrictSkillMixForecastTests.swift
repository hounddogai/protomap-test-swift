@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixForecastTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newStrictSkillMixForecast("code-433", label: "label-917")
        #expect(item.status == Staffing.StrictSkillMixForecastStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newStrictSkillMixForecast("code-433", label: "label-917")
        try item.moveTo(Staffing.StrictSkillMixForecastStatus.revoked)
        #expect(item.status == Staffing.StrictSkillMixForecastStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newStrictSkillMixForecast("code-433", label: "label-917")
        item.status = Staffing.StrictSkillMixForecastStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictSkillMixForecastStatus.requested) }
    }
}
