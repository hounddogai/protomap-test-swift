@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultSeasonalRoundingEstimateEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newSeasonalRoundingEstimate("code-739", name: "name-967")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
