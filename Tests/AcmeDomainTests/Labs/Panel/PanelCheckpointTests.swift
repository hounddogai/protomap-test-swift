@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelCheckpointTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelCheckpoint("code-925", label: "label-121")
        #expect(item.status == Labs.PanelCheckpointStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newPanelCheckpoint("code-925", label: "label-121")
        try item.moveTo(Labs.PanelCheckpointStatus.approved)
        #expect(item.status == Labs.PanelCheckpointStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelCheckpoint("code-925", label: "label-121")
        item.status = Labs.PanelCheckpointStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelCheckpointStatus.proposed) }
    }
}
