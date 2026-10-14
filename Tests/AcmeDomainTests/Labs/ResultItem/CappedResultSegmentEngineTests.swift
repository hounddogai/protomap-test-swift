@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCappedResultSegmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newCappedResultSegment("code-493", label: "label-917")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
