@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalTaskThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultSeasonalTaskThresholdEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newSeasonalTaskThreshold("code-38", name: "name-331")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
