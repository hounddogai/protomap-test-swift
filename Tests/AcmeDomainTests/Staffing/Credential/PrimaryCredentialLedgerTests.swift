@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialLedgerTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newPrimaryCredentialLedger("code-828", name: "name-719")
        #expect(item.status == Staffing.PrimaryCredentialLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newPrimaryCredentialLedger("code-828", name: "name-719")
        try item.moveTo(Staffing.PrimaryCredentialLedgerStatus.resolved)
        #expect(item.status == Staffing.PrimaryCredentialLedgerStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newPrimaryCredentialLedger("code-828", name: "name-719")
        item.status = Staffing.PrimaryCredentialLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryCredentialLedgerStatus.`open`) }
    }
}
