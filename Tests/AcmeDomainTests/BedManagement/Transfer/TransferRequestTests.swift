@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferRequestTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newTransferRequest("code-284", label: "label-127")
        #expect(item.status == BedManagement.TransferRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newTransferRequest("code-284", label: "label-127")
        try item.moveTo(BedManagement.TransferRequestStatus.pending)
        #expect(item.status == BedManagement.TransferRequestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newTransferRequest("code-284", label: "label-127")
        item.status = BedManagement.TransferRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferRequestStatus.draft) }
    }
}
