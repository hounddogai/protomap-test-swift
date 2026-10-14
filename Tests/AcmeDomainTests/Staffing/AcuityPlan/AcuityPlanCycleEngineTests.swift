@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultAcuityPlanCycleEngine(Kit.Flags.newRegistry())
        let item = Staffing.newAcuityPlanCycle("code-596", name: "name-311")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
