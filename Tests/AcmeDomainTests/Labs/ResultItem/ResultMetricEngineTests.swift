@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultMetricEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultMetric("code-337", name: "name-188")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
