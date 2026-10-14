@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelSnapshotTests {
    @Test func startsInProposed() throws {
        let item = Labs.newAdaptivePanelSnapshot("code-155", label: "label-152")
        #expect(item.status == Labs.AdaptivePanelSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newAdaptivePanelSnapshot("code-155", label: "label-152")
        try item.moveTo(Labs.AdaptivePanelSnapshotStatus.rejected)
        #expect(item.status == Labs.AdaptivePanelSnapshotStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newAdaptivePanelSnapshot("code-155", label: "label-152")
        item.status = Labs.AdaptivePanelSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptivePanelSnapshotStatus.proposed) }
    }
}
