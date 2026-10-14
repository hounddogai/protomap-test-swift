@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusCheckpointTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newGlobalCensusCheckpoint("code-794", title: "title-550")
        #expect(item.status == BedManagement.GlobalCensusCheckpointStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newGlobalCensusCheckpoint("code-794", title: "title-550")
        try item.moveTo(BedManagement.GlobalCensusCheckpointStatus.reopened)
        #expect(item.status == BedManagement.GlobalCensusCheckpointStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newGlobalCensusCheckpoint("code-794", title: "title-550")
        item.status = BedManagement.GlobalCensusCheckpointStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalCensusCheckpointStatus.`open`) }
    }
}
