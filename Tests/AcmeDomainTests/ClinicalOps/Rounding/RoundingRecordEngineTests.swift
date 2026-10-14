@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultRoundingRecordEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newRoundingRecord("code-251", label: "label-608")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
