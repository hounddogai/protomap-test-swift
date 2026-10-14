@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultTieredPanelForecastEngine(Kit.Flags.newRegistry())
        let item = Labs.newTieredPanelForecast("code-741", title: "title-730")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
