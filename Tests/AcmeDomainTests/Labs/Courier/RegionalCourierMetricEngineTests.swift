@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalCourierMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRegionalCourierMetricEngine(Kit.Flags.newRegistry())
        let item = Labs.newRegionalCourierMetric("code-953", label: "label-796")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
