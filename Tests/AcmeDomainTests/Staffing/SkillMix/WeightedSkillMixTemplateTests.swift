@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedSkillMixTemplateTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newWeightedSkillMixTemplate("code-223", label: "label-347")
        #expect(item.status == Staffing.WeightedSkillMixTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newWeightedSkillMixTemplate("code-223", label: "label-347")
        try item.moveTo(Staffing.WeightedSkillMixTemplateStatus.inProgress)
        #expect(item.status == Staffing.WeightedSkillMixTemplateStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newWeightedSkillMixTemplate("code-223", label: "label-347")
        item.status = Staffing.WeightedSkillMixTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedSkillMixTemplateStatus.planned) }
    }
}
