@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferBaselineTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newTransferBaseline("code-971", label: "label-591")
        #expect(item.status == BedManagement.TransferBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = BedManagement.newTransferBaseline("code-971", label: "label-591")
        try item.moveTo(BedManagement.TransferBaselineStatus.closed)
        #expect(item.status == BedManagement.TransferBaselineStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newTransferBaseline("code-971", label: "label-591")
        item.status = BedManagement.TransferBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferBaselineStatus.draft) }
    }
}
