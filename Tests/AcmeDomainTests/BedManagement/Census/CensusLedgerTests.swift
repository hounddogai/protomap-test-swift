@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusLedgerTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newCensusLedger("code-523", name: "name-22")
        #expect(item.status == BedManagement.CensusLedgerStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newCensusLedger("code-523", name: "name-22")
        try item.moveTo(BedManagement.CensusLedgerStatus.approved)
        #expect(item.status == BedManagement.CensusLedgerStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newCensusLedger("code-523", name: "name-22")
        item.status = BedManagement.CensusLedgerStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusLedgerStatus.proposed) }
    }
}
