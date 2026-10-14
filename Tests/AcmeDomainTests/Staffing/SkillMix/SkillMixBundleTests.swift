@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixBundleTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSkillMixBundle("code-688", title: "title-609")
        #expect(item.status == Staffing.SkillMixBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newSkillMixBundle("code-688", title: "title-609")
        try item.moveTo(Staffing.SkillMixBundleStatus.pending)
        #expect(item.status == Staffing.SkillMixBundleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSkillMixBundle("code-688", title: "title-609")
        item.status = Staffing.SkillMixBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixBundleStatus.draft) }
    }
}
