@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferManifestTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newTransferManifest("code-43", name: "name-441")
        #expect(item.status == BedManagement.TransferManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newTransferManifest("code-43", name: "name-441")
        try item.moveTo(BedManagement.TransferManifestStatus.pending)
        #expect(item.status == BedManagement.TransferManifestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newTransferManifest("code-43", name: "name-441")
        item.status = BedManagement.TransferManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferManifestStatus.draft) }
    }
}
