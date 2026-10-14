@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixReviewTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSkillMixReview("code-963", name: "name-626")
        #expect(item.status == Staffing.SkillMixReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newSkillMixReview("code-963", name: "name-626")
        try item.moveTo(Staffing.SkillMixReviewStatus.pending)
        #expect(item.status == Staffing.SkillMixReviewStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSkillMixReview("code-963", name: "name-626")
        item.status = Staffing.SkillMixReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixReviewStatus.draft) }
    }
}
