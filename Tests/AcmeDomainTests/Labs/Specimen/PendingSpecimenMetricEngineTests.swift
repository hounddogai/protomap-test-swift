@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingSpecimenMetricEngine()
        let item = Labs.newPendingSpecimenMetric("code-771", label: "label-856")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
