@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPrimarySkillMixCycleEngine()
        let item = Staffing.newPrimarySkillMixCycle("code-375", name: "name-567")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
