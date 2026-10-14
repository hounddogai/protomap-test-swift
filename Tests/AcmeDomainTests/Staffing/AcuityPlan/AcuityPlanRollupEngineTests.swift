@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultAcuityPlanRollupEngine(Kit.Flags.newRegistry())
        let item = Staffing.newAcuityPlanRollup("code-788", title: "title-380")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
