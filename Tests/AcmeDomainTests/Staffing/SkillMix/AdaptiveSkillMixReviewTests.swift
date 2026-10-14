@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveSkillMixReviewTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAdaptiveSkillMixReview("code-388", label: "label-74")
        #expect(item.status == Staffing.AdaptiveSkillMixReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newAdaptiveSkillMixReview("code-388", label: "label-74")
        try item.moveTo(Staffing.AdaptiveSkillMixReviewStatus.approved)
        #expect(item.status == Staffing.AdaptiveSkillMixReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAdaptiveSkillMixReview("code-388", label: "label-74")
        item.status = Staffing.AdaptiveSkillMixReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveSkillMixReviewStatus.proposed) }
    }
}
