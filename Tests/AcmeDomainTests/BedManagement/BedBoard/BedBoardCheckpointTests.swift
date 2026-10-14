@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardCheckpointTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newBedBoardCheckpoint("code-197", title: "title-827")
        #expect(item.status == BedManagement.BedBoardCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newBedBoardCheckpoint("code-197", title: "title-827")
        try item.moveTo(BedManagement.BedBoardCheckpointStatus.revoked)
        #expect(item.status == BedManagement.BedBoardCheckpointStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newBedBoardCheckpoint("code-197", title: "title-827")
        item.status = BedManagement.BedBoardCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardCheckpointStatus.requested) }
    }
}
