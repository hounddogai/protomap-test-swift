@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualReferenceRangeForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultManualReferenceRangeForecastEngine()
        let item = Labs.newManualReferenceRangeForecast("code-101", label: "label-782")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
