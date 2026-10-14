@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultSpecimenSegmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newSpecimenSegment("code-860", name: "name-318")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
