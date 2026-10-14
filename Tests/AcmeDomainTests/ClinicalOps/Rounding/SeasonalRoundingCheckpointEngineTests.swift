@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultSeasonalRoundingCheckpointEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newSeasonalRoundingCheckpoint("code-254", title: "title-456")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
