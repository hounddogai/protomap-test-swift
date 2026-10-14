@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixTemplateTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newFallbackSkillMixTemplate("code-447", label: "label-132")
        #expect(item.status == Staffing.FallbackSkillMixTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newFallbackSkillMixTemplate("code-447", label: "label-132")
        try item.moveTo(Staffing.FallbackSkillMixTemplateStatus.warming)
        #expect(item.status == Staffing.FallbackSkillMixTemplateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newFallbackSkillMixTemplate("code-447", label: "label-132")
        item.status = Staffing.FallbackSkillMixTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackSkillMixTemplateStatus.idle) }
    }
}
