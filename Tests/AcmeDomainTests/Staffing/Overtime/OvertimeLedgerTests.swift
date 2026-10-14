@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeLedgerTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newOvertimeLedger("code-345", title: "title-15")
        #expect(item.status == Staffing.OvertimeLedgerStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newOvertimeLedger("code-345", title: "title-15")
        try item.moveTo(Staffing.OvertimeLedgerStatus.rejected)
        #expect(item.status == Staffing.OvertimeLedgerStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newOvertimeLedger("code-345", title: "title-15")
        item.status = Staffing.OvertimeLedgerStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeLedgerStatus.proposed) }
    }
}
