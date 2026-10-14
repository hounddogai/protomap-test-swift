@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultSummaryEngine()
        let item = Labs.newResultSummary("code-534", label: "label-867")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
