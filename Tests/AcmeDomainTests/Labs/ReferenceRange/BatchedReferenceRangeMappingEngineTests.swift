@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedReferenceRangeMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultBatchedReferenceRangeMappingEngine()
        let item = Labs.newBatchedReferenceRangeMapping("code-297", name: "name-848")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
