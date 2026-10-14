@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardDigestTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCappedBedBoardDigest("code-999", name: "name-189")
        #expect(item.status == BedManagement.CappedBedBoardDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newCappedBedBoardDigest("code-999", name: "name-189")
        try item.moveTo(BedManagement.CappedBedBoardDigestStatus.draining)
        #expect(item.status == BedManagement.CappedBedBoardDigestStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCappedBedBoardDigest("code-999", name: "name-189")
        item.status = BedManagement.CappedBedBoardDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedBedBoardDigestStatus.idle) }
    }
}
