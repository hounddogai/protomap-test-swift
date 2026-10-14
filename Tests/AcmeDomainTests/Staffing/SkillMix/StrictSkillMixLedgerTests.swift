@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixLedgerTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newStrictSkillMixLedger("code-679", name: "name-382")
        #expect(item.status == Staffing.StrictSkillMixLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newStrictSkillMixLedger("code-679", name: "name-382")
        try item.moveTo(Staffing.StrictSkillMixLedgerStatus.resolved)
        #expect(item.status == Staffing.StrictSkillMixLedgerStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newStrictSkillMixLedger("code-679", name: "name-382")
        item.status = Staffing.StrictSkillMixLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictSkillMixLedgerStatus.`open`) }
    }
}
