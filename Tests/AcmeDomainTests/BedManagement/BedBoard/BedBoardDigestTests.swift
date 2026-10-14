@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardDigestTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newBedBoardDigest("code-466", label: "label-787")
        #expect(item.status == BedManagement.BedBoardDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newBedBoardDigest("code-466", label: "label-787")
        try item.moveTo(BedManagement.BedBoardDigestStatus.inProgress)
        #expect(item.status == BedManagement.BedBoardDigestStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newBedBoardDigest("code-466", label: "label-787")
        item.status = BedManagement.BedBoardDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardDigestStatus.planned) }
    }
}
