@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixForecastTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newSeasonalSkillMixForecast("code-678", name: "name-961")
        #expect(item.status == Staffing.SeasonalSkillMixForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newSeasonalSkillMixForecast("code-678", name: "name-961")
        try item.moveTo(Staffing.SeasonalSkillMixForecastStatus.validated)
        #expect(item.status == Staffing.SeasonalSkillMixForecastStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newSeasonalSkillMixForecast("code-678", name: "name-961")
        item.status = Staffing.SeasonalSkillMixForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalSkillMixForecastStatus.created) }
    }
}
