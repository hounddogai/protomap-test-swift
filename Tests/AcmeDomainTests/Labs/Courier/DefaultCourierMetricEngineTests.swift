@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultDefaultCourierMetricEngine()
        let item = Labs.newDefaultCourierMetric("code-43", label: "label-580")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
