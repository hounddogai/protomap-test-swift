@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictAcuityPlanBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultStrictAcuityPlanBundleEngine(Kit.Flags.newRegistry())
        let item = Staffing.newStrictAcuityPlanBundle("code-599", title: "title-451")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
