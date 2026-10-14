@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultReferenceRangeRecordEngine(Kit.Flags.newRegistry())
        let item = Labs.newReferenceRangeRecord("code-804", name: "name-164")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
