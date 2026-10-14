@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachCheckpointTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newOutreachCheckpoint("code-881", label: "label-719")
        #expect(item.status == CareManagement.OutreachCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newOutreachCheckpoint("code-881", label: "label-719")
        try item.moveTo(CareManagement.OutreachCheckpointStatus.warming)
        #expect(item.status == CareManagement.OutreachCheckpointStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newOutreachCheckpoint("code-881", label: "label-719")
        item.status = CareManagement.OutreachCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachCheckpointStatus.idle) }
    }
}
