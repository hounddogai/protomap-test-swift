@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingGoalCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRollingGoalCycleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRollingGoalCycle("code-329", title: "title-472")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
