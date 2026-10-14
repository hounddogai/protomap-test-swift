@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingResultForecastEngine(Kit.Flags.newRegistry())
        let item = Labs.newPendingResultForecast("code-278", label: "label-774")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
