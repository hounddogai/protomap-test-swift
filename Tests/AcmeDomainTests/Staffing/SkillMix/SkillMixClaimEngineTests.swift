@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSkillMixClaimEngine()
        let item = Staffing.newSkillMixClaim("code-227", title: "title-632")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
