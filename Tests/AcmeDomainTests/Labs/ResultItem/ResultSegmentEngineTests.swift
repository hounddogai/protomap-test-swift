@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultSegmentEngine()
        let item = Labs.newResultSegment("code-457", label: "label-798")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
