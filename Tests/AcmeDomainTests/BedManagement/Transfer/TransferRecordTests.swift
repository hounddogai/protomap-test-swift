@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferRecordTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newTransferRecord("code-703", label: "label-667")
        #expect(item.status == BedManagement.TransferRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newTransferRecord("code-703", label: "label-667")
        try item.moveTo(BedManagement.TransferRecordStatus.queued)
        #expect(item.status == BedManagement.TransferRecordStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newTransferRecord("code-703", label: "label-667")
        item.status = BedManagement.TransferRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferRecordStatus.new) }
    }
}
