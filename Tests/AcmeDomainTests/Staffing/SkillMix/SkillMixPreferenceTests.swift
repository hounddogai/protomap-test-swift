@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixPreferenceTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSkillMixPreference("code-449", label: "label-404")
        #expect(item.status == Staffing.SkillMixPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newSkillMixPreference("code-449", label: "label-404")
        try item.moveTo(Staffing.SkillMixPreferenceStatus.suspended)
        #expect(item.status == Staffing.SkillMixPreferenceStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSkillMixPreference("code-449", label: "label-404")
        item.status = Staffing.SkillMixPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixPreferenceStatus.draft) }
    }
}
