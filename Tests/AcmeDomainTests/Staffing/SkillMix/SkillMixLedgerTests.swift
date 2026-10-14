@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixLedgerTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newSkillMixLedger("code-703", label: "label-633")
        #expect(item.status == Staffing.SkillMixLedgerStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newSkillMixLedger("code-703", label: "label-633")
        try item.moveTo(Staffing.SkillMixLedgerStatus.inProgress)
        #expect(item.status == Staffing.SkillMixLedgerStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newSkillMixLedger("code-703", label: "label-633")
        item.status = Staffing.SkillMixLedgerStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixLedgerStatus.planned) }
    }
}
