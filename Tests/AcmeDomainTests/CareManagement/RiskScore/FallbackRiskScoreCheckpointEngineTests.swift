@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackRiskScoreCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultFallbackRiskScoreCheckpointEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newFallbackRiskScoreCheckpoint("code-911", title: "title-523")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
