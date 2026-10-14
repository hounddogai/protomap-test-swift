@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedGoalCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultWeightedGoalCycleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newWeightedGoalCycle("code-261", title: "title-945")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
