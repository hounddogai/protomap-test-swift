@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLegacyResultForecastEngine(Kit.Flags.newRegistry())
        let item = Labs.newLegacyResultForecast("code-222", title: "title-245")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
