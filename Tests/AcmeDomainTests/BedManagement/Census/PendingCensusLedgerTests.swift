@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusLedgerTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newPendingCensusLedger("code-765", label: "label-147")
        #expect(item.status == BedManagement.PendingCensusLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newPendingCensusLedger("code-765", label: "label-147")
        try item.moveTo(BedManagement.PendingCensusLedgerStatus.draining)
        #expect(item.status == BedManagement.PendingCensusLedgerStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newPendingCensusLedger("code-765", label: "label-147")
        item.status = BedManagement.PendingCensusLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingCensusLedgerStatus.idle) }
    }
}
