@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingResultSegmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newRollingResultSegment("code-635", label: "label-746")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
