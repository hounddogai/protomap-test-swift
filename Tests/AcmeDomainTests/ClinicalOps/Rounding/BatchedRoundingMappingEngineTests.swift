@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedRoundingMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultBatchedRoundingMappingEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newBatchedRoundingMapping("code-211", name: "name-659")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
