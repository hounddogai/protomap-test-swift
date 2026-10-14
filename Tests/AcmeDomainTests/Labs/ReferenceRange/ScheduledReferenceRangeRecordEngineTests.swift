@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledReferenceRangeRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultScheduledReferenceRangeRecordEngine()
        let item = Labs.newScheduledReferenceRangeRecord("code-551", label: "label-90")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
