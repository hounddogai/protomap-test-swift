@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalSkillMixLedgerTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newRegionalSkillMixLedger("code-139", title: "title-707")
        #expect(item.status == Staffing.RegionalSkillMixLedgerStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newRegionalSkillMixLedger("code-139", title: "title-707")
        try item.moveTo(Staffing.RegionalSkillMixLedgerStatus.inProgress)
        #expect(item.status == Staffing.RegionalSkillMixLedgerStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newRegionalSkillMixLedger("code-139", title: "title-707")
        item.status = Staffing.RegionalSkillMixLedgerStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalSkillMixLedgerStatus.planned) }
    }
}
