@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFallbackSkillMixReviewEngine(Kit.Flags.newRegistry())
        let item = Staffing.newFallbackSkillMixReview("code-650", name: "name-376")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
