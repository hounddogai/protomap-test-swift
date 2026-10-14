@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixRequestTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSkillMixRequest("code-177", name: "name-715")
        #expect(item.status == Staffing.SkillMixRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newSkillMixRequest("code-177", name: "name-715")
        try item.moveTo(Staffing.SkillMixRequestStatus.active)
        #expect(item.status == Staffing.SkillMixRequestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSkillMixRequest("code-177", name: "name-715")
        item.status = Staffing.SkillMixRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixRequestStatus.draft) }
    }
}
