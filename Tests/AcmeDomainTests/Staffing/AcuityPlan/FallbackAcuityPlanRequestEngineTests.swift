@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackAcuityPlanRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFallbackAcuityPlanRequestEngine(Kit.Flags.newRegistry())
        let item = Staffing.newFallbackAcuityPlanRequest("code-899", name: "name-709")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
