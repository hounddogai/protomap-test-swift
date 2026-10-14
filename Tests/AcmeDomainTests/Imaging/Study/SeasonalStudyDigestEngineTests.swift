@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultSeasonalStudyDigestEngine()
        let item = Imaging.newSeasonalStudyDigest("code-121", label: "label-770")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
