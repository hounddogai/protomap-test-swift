@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultTieredSkillMixClaimEngine()
        let item = Staffing.newTieredSkillMixClaim("code-34", name: "name-785")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
