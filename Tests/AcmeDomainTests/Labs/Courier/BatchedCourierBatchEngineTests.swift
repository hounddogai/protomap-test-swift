@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedCourierBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultBatchedCourierBatchEngine(Kit.Flags.newRegistry())
        let item = Labs.newBatchedCourierBatch("code-250", label: "label-514")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
