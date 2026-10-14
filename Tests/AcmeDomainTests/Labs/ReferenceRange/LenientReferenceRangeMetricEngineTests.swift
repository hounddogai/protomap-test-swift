@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientReferenceRangeMetricEngine()
        let item = Labs.newLenientReferenceRangeMetric("code-705", title: "title-531")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
