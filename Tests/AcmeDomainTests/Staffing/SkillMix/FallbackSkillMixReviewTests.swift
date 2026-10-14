@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixReviewTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newFallbackSkillMixReview("code-650", name: "name-376")
        #expect(item.status == Staffing.FallbackSkillMixReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newFallbackSkillMixReview("code-650", name: "name-376")
        try item.moveTo(Staffing.FallbackSkillMixReviewStatus.resolved)
        #expect(item.status == Staffing.FallbackSkillMixReviewStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newFallbackSkillMixReview("code-650", name: "name-376")
        item.status = Staffing.FallbackSkillMixReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackSkillMixReviewStatus.`open`) }
    }
}
