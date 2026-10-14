@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferSnapshotTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newTransferSnapshot("code-388", name: "name-780")
        #expect(item.status == BedManagement.TransferSnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newTransferSnapshot("code-388", name: "name-780")
        try item.moveTo(BedManagement.TransferSnapshotStatus.validated)
        #expect(item.status == BedManagement.TransferSnapshotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newTransferSnapshot("code-388", name: "name-780")
        item.status = BedManagement.TransferSnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferSnapshotStatus.created) }
    }
}
