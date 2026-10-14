@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedSkillMixCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultBatchedSkillMixCycleEngine(Kit.Flags.newRegistry())
        let item = Staffing.newBatchedSkillMixCycle("code-713", title: "title-548")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
