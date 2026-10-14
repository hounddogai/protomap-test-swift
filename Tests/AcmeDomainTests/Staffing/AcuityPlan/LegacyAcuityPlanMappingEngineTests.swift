@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyAcuityPlanMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLegacyAcuityPlanMappingEngine(Kit.Flags.newRegistry())
        let item = Staffing.newLegacyAcuityPlanMapping("code-927", name: "name-51")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
