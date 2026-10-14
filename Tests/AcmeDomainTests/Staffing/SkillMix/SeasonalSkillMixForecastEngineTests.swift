@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSeasonalSkillMixForecastEngine()
        let item = Staffing.newSeasonalSkillMixForecast("code-678", name: "name-961")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
