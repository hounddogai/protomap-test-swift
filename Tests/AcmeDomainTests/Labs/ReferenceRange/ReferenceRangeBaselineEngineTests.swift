@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultReferenceRangeBaselineEngine(Kit.Flags.newRegistry())
        let item = Labs.newReferenceRangeBaseline("code-310", name: "name-660")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
