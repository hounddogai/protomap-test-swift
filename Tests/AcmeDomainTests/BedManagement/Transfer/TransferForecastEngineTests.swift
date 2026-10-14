@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTransferForecastEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newTransferForecast("code-955", name: "name-384")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
