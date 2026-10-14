@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingOutreachCheckpointTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newPendingOutreachCheckpoint("code-549", label: "label-460")
        #expect(item.status == CareManagement.PendingOutreachCheckpointStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newPendingOutreachCheckpoint("code-549", label: "label-460")
        try item.moveTo(CareManagement.PendingOutreachCheckpointStatus.approved)
        #expect(item.status == CareManagement.PendingOutreachCheckpointStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newPendingOutreachCheckpoint("code-549", label: "label-460")
        item.status = CareManagement.PendingOutreachCheckpointStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingOutreachCheckpointStatus.proposed) }
    }
}
