@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardLedgerTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newPrimaryBedBoardLedger("code-432", label: "label-715")
        #expect(item.status == BedManagement.PrimaryBedBoardLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = BedManagement.newPrimaryBedBoardLedger("code-432", label: "label-715")
        try item.moveTo(BedManagement.PrimaryBedBoardLedgerStatus.retired)
        #expect(item.status == BedManagement.PrimaryBedBoardLedgerStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newPrimaryBedBoardLedger("code-432", label: "label-715")
        item.status = BedManagement.PrimaryBedBoardLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryBedBoardLedgerStatus.created) }
    }
}
