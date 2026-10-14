@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalAcuityPlanForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultGlobalAcuityPlanForecastEngine()
        let item = Staffing.newGlobalAcuityPlanForecast("code-101", label: "label-32")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
