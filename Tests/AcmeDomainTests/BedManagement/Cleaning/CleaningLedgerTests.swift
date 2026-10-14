@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningLedgerTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCleaningLedger("code-895", label: "label-898")
        #expect(item.status == BedManagement.CleaningLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newCleaningLedger("code-895", label: "label-898")
        try item.moveTo(BedManagement.CleaningLedgerStatus.running)
        #expect(item.status == BedManagement.CleaningLedgerStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCleaningLedger("code-895", label: "label-898")
        item.status = BedManagement.CleaningLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningLedgerStatus.new) }
    }
}
