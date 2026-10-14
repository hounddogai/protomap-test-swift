@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredBedBoardDigestTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newTieredBedBoardDigest("code-943", name: "name-800")
        #expect(item.status == BedManagement.TieredBedBoardDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newTieredBedBoardDigest("code-943", name: "name-800")
        try item.moveTo(BedManagement.TieredBedBoardDigestStatus.pending)
        #expect(item.status == BedManagement.TieredBedBoardDigestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newTieredBedBoardDigest("code-943", name: "name-800")
        item.status = BedManagement.TieredBedBoardDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TieredBedBoardDigestStatus.draft) }
    }
}
