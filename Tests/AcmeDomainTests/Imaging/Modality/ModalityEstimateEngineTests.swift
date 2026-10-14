@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultModalityEstimateEngine(Kit.Flags.newRegistry())
        let item = Imaging.newModalityEstimate("code-958", label: "label-664")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
