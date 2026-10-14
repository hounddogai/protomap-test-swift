@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferEntryTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newTransferEntry("code-131", label: "label-333")
        #expect(item.status == BedManagement.TransferEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = BedManagement.newTransferEntry("code-131", label: "label-333")
        try item.moveTo(BedManagement.TransferEntryStatus.failed)
        #expect(item.status == BedManagement.TransferEntryStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newTransferEntry("code-131", label: "label-333")
        item.status = BedManagement.TransferEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferEntryStatus.new) }
    }
}
