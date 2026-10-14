@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixForecastTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newSkillMixForecast("code-186", title: "title-686")
        #expect(item.status == Staffing.SkillMixForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newSkillMixForecast("code-186", title: "title-686")
        try item.moveTo(Staffing.SkillMixForecastStatus.resolved)
        #expect(item.status == Staffing.SkillMixForecastStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newSkillMixForecast("code-186", title: "title-686")
        item.status = Staffing.SkillMixForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixForecastStatus.`open`) }
    }
}
