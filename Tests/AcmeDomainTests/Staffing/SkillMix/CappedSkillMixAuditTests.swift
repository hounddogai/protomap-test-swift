@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixAuditTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newCappedSkillMixAudit("code-318", label: "label-772")
        #expect(item.status == Staffing.CappedSkillMixAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newCappedSkillMixAudit("code-318", label: "label-772")
        try item.moveTo(Staffing.CappedSkillMixAuditStatus.approved)
        #expect(item.status == Staffing.CappedSkillMixAuditStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newCappedSkillMixAudit("code-318", label: "label-772")
        item.status = Staffing.CappedSkillMixAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedSkillMixAuditStatus.proposed) }
    }
}
