@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyModalityThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultLegacyModalityThresholdEngine(Kit.Flags.newRegistry())
        let item = Imaging.newLegacyModalityThreshold("code-84", name: "name-656")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
