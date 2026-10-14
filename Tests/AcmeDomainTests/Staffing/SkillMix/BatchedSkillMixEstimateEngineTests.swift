@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedSkillMixEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultBatchedSkillMixEstimateEngine(Kit.Flags.newRegistry())
        let item = Staffing.newBatchedSkillMixEstimate("code-217", title: "title-298")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
