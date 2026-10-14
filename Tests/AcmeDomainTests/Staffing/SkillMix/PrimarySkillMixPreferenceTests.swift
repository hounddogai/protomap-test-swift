@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixPreferenceTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newPrimarySkillMixPreference("code-294", label: "label-440")
        #expect(item.status == Staffing.PrimarySkillMixPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newPrimarySkillMixPreference("code-294", label: "label-440")
        try item.moveTo(Staffing.PrimarySkillMixPreferenceStatus.approved)
        #expect(item.status == Staffing.PrimarySkillMixPreferenceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newPrimarySkillMixPreference("code-294", label: "label-440")
        item.status = Staffing.PrimarySkillMixPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimarySkillMixPreferenceStatus.proposed) }
    }
}
