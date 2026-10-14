@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledSkillMixEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultScheduledSkillMixEstimateEngine(Kit.Flags.newRegistry())
        let item = Staffing.newScheduledSkillMixEstimate("code-972", label: "label-44")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
