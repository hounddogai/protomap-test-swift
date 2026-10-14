@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixClaimTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newSkillMixClaim("code-227", title: "title-632")
        #expect(item.status == Staffing.SkillMixClaimStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newSkillMixClaim("code-227", title: "title-632")
        try item.moveTo(Staffing.SkillMixClaimStatus.ready)
        #expect(item.status == Staffing.SkillMixClaimStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newSkillMixClaim("code-227", title: "title-632")
        item.status = Staffing.SkillMixClaimStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixClaimStatus.idle) }
    }
}
