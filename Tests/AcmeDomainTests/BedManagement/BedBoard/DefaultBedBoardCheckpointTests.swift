@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardCheckpointTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newDefaultBedBoardCheckpoint("code-415", name: "name-897")
        #expect(item.status == BedManagement.DefaultBedBoardCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newDefaultBedBoardCheckpoint("code-415", name: "name-897")
        try item.moveTo(BedManagement.DefaultBedBoardCheckpointStatus.done)
        #expect(item.status == BedManagement.DefaultBedBoardCheckpointStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newDefaultBedBoardCheckpoint("code-415", name: "name-897")
        item.status = BedManagement.DefaultBedBoardCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultBedBoardCheckpointStatus.new) }
    }
}
