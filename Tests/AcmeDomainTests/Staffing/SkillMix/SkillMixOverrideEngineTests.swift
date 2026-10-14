@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSkillMixOverrideEngine(Kit.Flags.newRegistry())
        let item = Staffing.newSkillMixOverride("code-940", title: "title-241")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
