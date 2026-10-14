@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultAcuityPlanEstimateEngine(Kit.Flags.newRegistry())
        let item = Staffing.newAcuityPlanEstimate("code-423", label: "label-49")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
