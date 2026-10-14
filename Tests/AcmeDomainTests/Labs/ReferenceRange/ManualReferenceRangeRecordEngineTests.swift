@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualReferenceRangeRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultManualReferenceRangeRecordEngine(Kit.Flags.newRegistry())
        let item = Labs.newManualReferenceRangeRecord("code-389", label: "label-321")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
