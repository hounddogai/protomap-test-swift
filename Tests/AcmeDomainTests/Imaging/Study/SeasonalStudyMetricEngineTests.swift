@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultSeasonalStudyMetricEngine()
        let item = Imaging.newSeasonalStudyMetric("code-411", label: "label-585")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
