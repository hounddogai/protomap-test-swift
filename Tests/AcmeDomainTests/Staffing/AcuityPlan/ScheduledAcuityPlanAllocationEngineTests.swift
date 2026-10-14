@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultScheduledAcuityPlanAllocationEngine(Kit.Flags.newRegistry())
        let item = Staffing.newScheduledAcuityPlanAllocation("code-975", label: "label-735")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
