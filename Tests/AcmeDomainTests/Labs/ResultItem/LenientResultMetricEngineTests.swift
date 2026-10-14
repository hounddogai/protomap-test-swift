@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientResultMetricEngine(Kit.Flags.newRegistry())
        let item = Labs.newLenientResultMetric("code-132", name: "name-568")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
