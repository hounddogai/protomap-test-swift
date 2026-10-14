@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingSkillMixDigestTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newPendingSkillMixDigest("code-240", title: "title-982")
        #expect(item.status == Staffing.PendingSkillMixDigestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newPendingSkillMixDigest("code-240", title: "title-982")
        try item.moveTo(Staffing.PendingSkillMixDigestStatus.reopened)
        #expect(item.status == Staffing.PendingSkillMixDigestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newPendingSkillMixDigest("code-240", title: "title-982")
        item.status = Staffing.PendingSkillMixDigestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingSkillMixDigestStatus.`open`) }
    }
}
