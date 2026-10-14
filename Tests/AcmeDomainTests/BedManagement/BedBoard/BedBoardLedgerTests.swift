@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardLedgerTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newBedBoardLedger("code-617", name: "name-303")
        #expect(item.status == BedManagement.BedBoardLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newBedBoardLedger("code-617", name: "name-303")
        try item.moveTo(BedManagement.BedBoardLedgerStatus.resolved)
        #expect(item.status == BedManagement.BedBoardLedgerStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newBedBoardLedger("code-617", name: "name-303")
        item.status = BedManagement.BedBoardLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardLedgerStatus.`open`) }
    }
}
