@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedCredentialLedgerTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newCappedCredentialLedger("code-364", name: "name-105")
        #expect(item.status == Staffing.CappedCredentialLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newCappedCredentialLedger("code-364", name: "name-105")
        try item.moveTo(Staffing.CappedCredentialLedgerStatus.published)
        #expect(item.status == Staffing.CappedCredentialLedgerStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newCappedCredentialLedger("code-364", name: "name-105")
        item.status = Staffing.CappedCredentialLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedCredentialLedgerStatus.created) }
    }
}
