@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferCheckpointTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newTransferCheckpoint("code-274", title: "title-261")
        #expect(item.status == BedManagement.TransferCheckpointStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newTransferCheckpoint("code-274", title: "title-261")
        try item.moveTo(BedManagement.TransferCheckpointStatus.validated)
        #expect(item.status == BedManagement.TransferCheckpointStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newTransferCheckpoint("code-274", title: "title-261")
        item.status = BedManagement.TransferCheckpointStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferCheckpointStatus.created) }
    }
}
