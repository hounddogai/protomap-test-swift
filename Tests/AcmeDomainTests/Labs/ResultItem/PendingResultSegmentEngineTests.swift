@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingResultSegmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newPendingResultSegment("code-541", title: "title-352")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
