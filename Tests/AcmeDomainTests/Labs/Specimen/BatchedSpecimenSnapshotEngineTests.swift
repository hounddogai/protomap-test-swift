@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedSpecimenSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultBatchedSpecimenSnapshotEngine(Kit.Flags.newRegistry())
        let item = Labs.newBatchedSpecimenSnapshot("code-528", name: "name-954")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
