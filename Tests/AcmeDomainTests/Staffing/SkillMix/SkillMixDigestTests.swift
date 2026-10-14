@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixDigestTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newSkillMixDigest("code-488", label: "label-317")
        #expect(item.status == Staffing.SkillMixDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newSkillMixDigest("code-488", label: "label-317")
        try item.moveTo(Staffing.SkillMixDigestStatus.revoked)
        #expect(item.status == Staffing.SkillMixDigestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newSkillMixDigest("code-488", label: "label-317")
        item.status = Staffing.SkillMixDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixDigestStatus.requested) }
    }
}
