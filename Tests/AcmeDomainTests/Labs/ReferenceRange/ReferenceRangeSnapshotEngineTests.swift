@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultReferenceRangeSnapshotEngine()
        let item = Labs.newReferenceRangeSnapshot("code-156", title: "title-520")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
