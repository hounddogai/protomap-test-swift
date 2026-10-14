@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalOvertimeLedgerTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newGlobalOvertimeLedger("code-989", name: "name-923")
        #expect(item.status == Staffing.GlobalOvertimeLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newGlobalOvertimeLedger("code-989", name: "name-923")
        try item.moveTo(Staffing.GlobalOvertimeLedgerStatus.pending)
        #expect(item.status == Staffing.GlobalOvertimeLedgerStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newGlobalOvertimeLedger("code-989", name: "name-923")
        item.status = Staffing.GlobalOvertimeLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalOvertimeLedgerStatus.draft) }
    }
}
