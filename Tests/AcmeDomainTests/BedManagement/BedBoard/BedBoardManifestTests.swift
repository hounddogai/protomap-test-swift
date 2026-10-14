@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardManifestTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newBedBoardManifest("code-369", name: "name-733")
        #expect(item.status == BedManagement.BedBoardManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newBedBoardManifest("code-369", name: "name-733")
        try item.moveTo(BedManagement.BedBoardManifestStatus.inProgress)
        #expect(item.status == BedManagement.BedBoardManifestStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newBedBoardManifest("code-369", name: "name-733")
        item.status = BedManagement.BedBoardManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardManifestStatus.planned) }
    }
}
