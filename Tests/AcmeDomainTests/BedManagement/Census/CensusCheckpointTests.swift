@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusCheckpointTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCensusCheckpoint("code-271", label: "label-859")
        #expect(item.status == BedManagement.CensusCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newCensusCheckpoint("code-271", label: "label-859")
        try item.moveTo(BedManagement.CensusCheckpointStatus.ready)
        #expect(item.status == BedManagement.CensusCheckpointStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCensusCheckpoint("code-271", label: "label-859")
        item.status = BedManagement.CensusCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusCheckpointStatus.idle) }
    }
}
