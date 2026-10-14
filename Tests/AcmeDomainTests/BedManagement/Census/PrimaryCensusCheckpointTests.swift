@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusCheckpointTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newPrimaryCensusCheckpoint("code-768", title: "title-539")
        #expect(item.status == BedManagement.PrimaryCensusCheckpointStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newPrimaryCensusCheckpoint("code-768", title: "title-539")
        try item.moveTo(BedManagement.PrimaryCensusCheckpointStatus.rejected)
        #expect(item.status == BedManagement.PrimaryCensusCheckpointStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newPrimaryCensusCheckpoint("code-768", title: "title-539")
        item.status = BedManagement.PrimaryCensusCheckpointStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryCensusCheckpointStatus.proposed) }
    }
}
