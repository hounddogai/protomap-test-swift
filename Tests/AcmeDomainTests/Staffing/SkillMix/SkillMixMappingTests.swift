@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixMappingTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newSkillMixMapping("code-988", label: "label-662")
        #expect(item.status == Staffing.SkillMixMappingStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newSkillMixMapping("code-988", label: "label-662")
        try item.moveTo(Staffing.SkillMixMappingStatus.validated)
        #expect(item.status == Staffing.SkillMixMappingStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newSkillMixMapping("code-988", label: "label-662")
        item.status = Staffing.SkillMixMappingStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixMappingStatus.created) }
    }
}
