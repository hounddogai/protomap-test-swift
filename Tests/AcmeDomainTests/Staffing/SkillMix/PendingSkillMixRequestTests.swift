@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingSkillMixRequestTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newPendingSkillMixRequest("code-279", name: "name-639")
        #expect(item.status == Staffing.PendingSkillMixRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newPendingSkillMixRequest("code-279", name: "name-639")
        try item.moveTo(Staffing.PendingSkillMixRequestStatus.published)
        #expect(item.status == Staffing.PendingSkillMixRequestStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newPendingSkillMixRequest("code-279", name: "name-639")
        item.status = Staffing.PendingSkillMixRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingSkillMixRequestStatus.created) }
    }
}
