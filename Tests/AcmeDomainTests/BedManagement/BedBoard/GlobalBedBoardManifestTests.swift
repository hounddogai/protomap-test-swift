@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalBedBoardManifestTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newGlobalBedBoardManifest("code-586", label: "label-940")
        #expect(item.status == BedManagement.GlobalBedBoardManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newGlobalBedBoardManifest("code-586", label: "label-940")
        try item.moveTo(BedManagement.GlobalBedBoardManifestStatus.inProgress)
        #expect(item.status == BedManagement.GlobalBedBoardManifestStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newGlobalBedBoardManifest("code-586", label: "label-940")
        item.status = BedManagement.GlobalBedBoardManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalBedBoardManifestStatus.planned) }
    }
}
