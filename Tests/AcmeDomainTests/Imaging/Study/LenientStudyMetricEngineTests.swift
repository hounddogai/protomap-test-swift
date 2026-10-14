@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultLenientStudyMetricEngine(Kit.Flags.newRegistry())
        let item = Imaging.newLenientStudyMetric("code-795", label: "label-197")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
