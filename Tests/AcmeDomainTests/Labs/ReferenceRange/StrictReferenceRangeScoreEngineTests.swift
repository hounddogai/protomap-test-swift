@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictReferenceRangeScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultStrictReferenceRangeScoreEngine()
        let item = Labs.newStrictReferenceRangeScore("code-68", label: "label-130")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
