@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryProgramCheckpointTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newPrimaryProgramCheckpoint("code-683", title: "title-882")
        #expect(item.status == CareManagement.PrimaryProgramCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newPrimaryProgramCheckpoint("code-683", title: "title-882")
        try item.moveTo(CareManagement.PrimaryProgramCheckpointStatus.ready)
        #expect(item.status == CareManagement.PrimaryProgramCheckpointStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newPrimaryProgramCheckpoint("code-683", title: "title-882")
        item.status = CareManagement.PrimaryProgramCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryProgramCheckpointStatus.idle) }
    }
}
