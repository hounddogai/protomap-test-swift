@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixOverrideTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newStrictSkillMixOverride("code-739", name: "name-341")
        #expect(item.status == Staffing.StrictSkillMixOverrideStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newStrictSkillMixOverride("code-739", name: "name-341")
        try item.moveTo(Staffing.StrictSkillMixOverrideStatus.approved)
        #expect(item.status == Staffing.StrictSkillMixOverrideStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newStrictSkillMixOverride("code-739", name: "name-341")
        item.status = Staffing.StrictSkillMixOverrideStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictSkillMixOverrideStatus.proposed) }
    }
}
