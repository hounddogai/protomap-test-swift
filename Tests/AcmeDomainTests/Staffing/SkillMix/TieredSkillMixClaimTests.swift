@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixClaimTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newTieredSkillMixClaim("code-34", name: "name-785")
        #expect(item.status == Staffing.TieredSkillMixClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newTieredSkillMixClaim("code-34", name: "name-785")
        try item.moveTo(Staffing.TieredSkillMixClaimStatus.rejected)
        #expect(item.status == Staffing.TieredSkillMixClaimStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newTieredSkillMixClaim("code-34", name: "name-785")
        item.status = Staffing.TieredSkillMixClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredSkillMixClaimStatus.proposed) }
    }
}
