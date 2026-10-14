@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledDischargePlanForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultScheduledDischargePlanForecastEngine()
        let item = BedManagement.newScheduledDischargePlanForecast("code-643", label: "label-170")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
