@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultStrictSkillMixReviewEngine()
        let item = Staffing.newStrictSkillMixReview("code-418", name: "name-653")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
