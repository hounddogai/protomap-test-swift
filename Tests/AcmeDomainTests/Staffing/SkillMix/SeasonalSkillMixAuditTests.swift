@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixAuditTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newSeasonalSkillMixAudit("code-884", title: "title-806")
        #expect(item.status == Staffing.SeasonalSkillMixAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newSeasonalSkillMixAudit("code-884", title: "title-806")
        try item.moveTo(Staffing.SeasonalSkillMixAuditStatus.validated)
        #expect(item.status == Staffing.SeasonalSkillMixAuditStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newSeasonalSkillMixAudit("code-884", title: "title-806")
        item.status = Staffing.SeasonalSkillMixAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalSkillMixAuditStatus.created) }
    }
}
