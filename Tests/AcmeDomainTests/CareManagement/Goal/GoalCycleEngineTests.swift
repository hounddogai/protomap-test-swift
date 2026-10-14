@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGoalCycleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newGoalCycle("code-843", name: "name-87")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
