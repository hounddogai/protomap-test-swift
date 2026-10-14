@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCappedCleaningForecastEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCappedCleaningForecast("code-889", title: "title-477")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
