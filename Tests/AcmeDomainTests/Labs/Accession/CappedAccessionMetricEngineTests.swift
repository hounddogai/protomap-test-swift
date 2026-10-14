@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCappedAccessionMetricEngine(Kit.Flags.newRegistry())
        let item = Labs.newCappedAccessionMetric("code-101", title: "title-470")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
