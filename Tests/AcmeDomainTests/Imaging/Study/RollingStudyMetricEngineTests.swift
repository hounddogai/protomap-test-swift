@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultRollingStudyMetricEngine()
        let item = Imaging.newRollingStudyMetric("code-779", name: "name-482")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
