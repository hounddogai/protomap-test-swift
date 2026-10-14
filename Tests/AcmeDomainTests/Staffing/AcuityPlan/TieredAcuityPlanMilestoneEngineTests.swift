@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultTieredAcuityPlanMilestoneEngine(Kit.Flags.newRegistry())
        let item = Staffing.newTieredAcuityPlanMilestone("code-452", name: "name-213")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
