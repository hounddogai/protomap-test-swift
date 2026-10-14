@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalSkillMixProfileTests {
    @Test func startsInNew() throws {
        let item = Staffing.newRegionalSkillMixProfile("code-837", name: "name-892")
        #expect(item.status == Staffing.RegionalSkillMixProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Staffing.newRegionalSkillMixProfile("code-837", name: "name-892")
        try item.moveTo(Staffing.RegionalSkillMixProfileStatus.done)
        #expect(item.status == Staffing.RegionalSkillMixProfileStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newRegionalSkillMixProfile("code-837", name: "name-892")
        item.status = Staffing.RegionalSkillMixProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalSkillMixProfileStatus.new) }
    }
}
