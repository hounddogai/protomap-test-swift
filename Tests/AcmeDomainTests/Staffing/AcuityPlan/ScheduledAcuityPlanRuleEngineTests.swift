@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultScheduledAcuityPlanRuleEngine(Kit.Flags.newRegistry())
        let item = Staffing.newScheduledAcuityPlanRule("code-973", label: "label-739")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
