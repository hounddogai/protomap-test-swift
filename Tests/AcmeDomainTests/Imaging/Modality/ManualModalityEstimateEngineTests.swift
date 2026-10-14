@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualModalityEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultManualModalityEstimateEngine()
        let item = Imaging.newManualModalityEstimate("code-846", label: "label-238")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
