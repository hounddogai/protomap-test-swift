@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSeasonalAcuityPlanBudgetEngine(Kit.Flags.newRegistry())
        let item = Staffing.newSeasonalAcuityPlanBudget("code-538", name: "name-531")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
