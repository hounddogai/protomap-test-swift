@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachCheckpointTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newPrimaryOutreachCheckpoint("code-631", label: "label-95")
        #expect(item.status == CareManagement.PrimaryOutreachCheckpointStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newPrimaryOutreachCheckpoint("code-631", label: "label-95")
        try item.moveTo(CareManagement.PrimaryOutreachCheckpointStatus.active)
        #expect(item.status == CareManagement.PrimaryOutreachCheckpointStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newPrimaryOutreachCheckpoint("code-631", label: "label-95")
        item.status = CareManagement.PrimaryOutreachCheckpointStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryOutreachCheckpointStatus.draft) }
    }
}
