@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferLedgerTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newTransferLedger("code-364", label: "label-631")
        #expect(item.status == BedManagement.TransferLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newTransferLedger("code-364", label: "label-631")
        try item.moveTo(BedManagement.TransferLedgerStatus.revoked)
        #expect(item.status == BedManagement.TransferLedgerStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newTransferLedger("code-364", label: "label-631")
        item.status = BedManagement.TransferLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferLedgerStatus.requested) }
    }
}
