@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultFallbackGoalRollupEngine()
        let item = CareManagement.newFallbackGoalRollup("code-892", name: "name-576")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
