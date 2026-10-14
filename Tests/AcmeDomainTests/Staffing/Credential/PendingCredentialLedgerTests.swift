@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialLedgerTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newPendingCredentialLedger("code-819", name: "name-226")
        #expect(item.status == Staffing.PendingCredentialLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newPendingCredentialLedger("code-819", name: "name-226")
        try item.moveTo(Staffing.PendingCredentialLedgerStatus.granted)
        #expect(item.status == Staffing.PendingCredentialLedgerStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newPendingCredentialLedger("code-819", name: "name-226")
        item.status = Staffing.PendingCredentialLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingCredentialLedgerStatus.requested) }
    }
}
