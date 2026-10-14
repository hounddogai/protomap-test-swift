@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixAuditTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newStrictSkillMixAudit("code-759", name: "name-642")
        #expect(item.status == Staffing.StrictSkillMixAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newStrictSkillMixAudit("code-759", name: "name-642")
        try item.moveTo(Staffing.StrictSkillMixAuditStatus.revoked)
        #expect(item.status == Staffing.StrictSkillMixAuditStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newStrictSkillMixAudit("code-759", name: "name-642")
        item.status = Staffing.StrictSkillMixAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictSkillMixAuditStatus.requested) }
    }
}
