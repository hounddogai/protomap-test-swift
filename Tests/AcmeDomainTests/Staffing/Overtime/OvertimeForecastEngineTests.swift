@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultOvertimeForecastEngine(Kit.Flags.newRegistry())
        let item = Staffing.newOvertimeForecast("code-183", label: "label-447")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
