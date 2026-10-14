@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAccessionForecastEngine(Kit.Flags.newRegistry())
        let item = Labs.newAccessionForecast("code-663", title: "title-919")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
