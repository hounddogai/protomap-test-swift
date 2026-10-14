@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixProfileTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newSkillMixProfile("code-216", name: "name-905")
        #expect(item.status == Staffing.SkillMixProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Staffing.newSkillMixProfile("code-216", name: "name-905")
        try item.moveTo(Staffing.SkillMixProfileStatus.retired)
        #expect(item.status == Staffing.SkillMixProfileStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newSkillMixProfile("code-216", name: "name-905")
        item.status = Staffing.SkillMixProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixProfileStatus.created) }
    }
}
