@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalCleaningLedgerTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newRegionalCleaningLedger("code-523", name: "name-736")
        #expect(item.status == BedManagement.RegionalCleaningLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newRegionalCleaningLedger("code-523", name: "name-736")
        try item.moveTo(BedManagement.RegionalCleaningLedgerStatus.validated)
        #expect(item.status == BedManagement.RegionalCleaningLedgerStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newRegionalCleaningLedger("code-523", name: "name-736")
        item.status = BedManagement.RegionalCleaningLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalCleaningLedgerStatus.created) }
    }
}
