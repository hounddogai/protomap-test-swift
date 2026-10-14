@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedAcuityPlanAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCappedAcuityPlanAssignmentEngine(Kit.Flags.newRegistry())
        let item = Staffing.newCappedAcuityPlanAssignment("code-163", title: "title-325")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
