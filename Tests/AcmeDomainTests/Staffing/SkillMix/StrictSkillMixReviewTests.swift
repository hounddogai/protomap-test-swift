@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixReviewTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newStrictSkillMixReview("code-418", name: "name-653")
        #expect(item.status == Staffing.StrictSkillMixReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newStrictSkillMixReview("code-418", name: "name-653")
        try item.moveTo(Staffing.StrictSkillMixReviewStatus.rejected)
        #expect(item.status == Staffing.StrictSkillMixReviewStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newStrictSkillMixReview("code-418", name: "name-653")
        item.status = Staffing.StrictSkillMixReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictSkillMixReviewStatus.proposed) }
    }
}
