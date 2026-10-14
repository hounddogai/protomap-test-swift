@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingResultMetricEngine(Kit.Flags.newRegistry())
        let item = Labs.newPendingResultMetric("code-165", label: "label-670")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
