@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualSpecimenSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultManualSpecimenSegmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newManualSpecimenSegment("code-657", title: "title-927")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
