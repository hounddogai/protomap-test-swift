@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWorklistMetricEngine()
        let item = Imaging.newWorklistMetric("code-155", name: "name-882")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
