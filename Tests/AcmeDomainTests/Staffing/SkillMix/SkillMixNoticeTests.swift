@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixNoticeTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSkillMixNotice("code-56", name: "name-376")
        #expect(item.status == Staffing.SkillMixNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newSkillMixNotice("code-56", name: "name-376")
        try item.moveTo(Staffing.SkillMixNoticeStatus.pending)
        #expect(item.status == Staffing.SkillMixNoticeStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSkillMixNotice("code-56", name: "name-376")
        item.status = Staffing.SkillMixNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixNoticeStatus.draft) }
    }
}
