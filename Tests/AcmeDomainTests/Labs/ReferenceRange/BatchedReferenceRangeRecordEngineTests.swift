@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedReferenceRangeRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultBatchedReferenceRangeRecordEngine(Kit.Flags.newRegistry())
        let item = Labs.newBatchedReferenceRangeRecord("code-576", title: "title-512")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
