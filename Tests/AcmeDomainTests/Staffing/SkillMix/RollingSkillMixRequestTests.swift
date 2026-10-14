@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingSkillMixRequestTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newRollingSkillMixRequest("code-882", title: "title-714")
        #expect(item.status == Staffing.RollingSkillMixRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newRollingSkillMixRequest("code-882", title: "title-714")
        try item.moveTo(Staffing.RollingSkillMixRequestStatus.resolved)
        #expect(item.status == Staffing.RollingSkillMixRequestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newRollingSkillMixRequest("code-882", title: "title-714")
        item.status = Staffing.RollingSkillMixRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingSkillMixRequestStatus.`open`) }
    }
}
