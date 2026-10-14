@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAssignmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPanelAssignment("code-314", title: "title-204")
        #expect(item.status == Labs.PanelAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newPanelAssignment("code-314", title: "title-204")
        try item.moveTo(Labs.PanelAssignmentStatus.pending)
        #expect(item.status == Labs.PanelAssignmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPanelAssignment("code-314", title: "title-204")
        item.status = Labs.PanelAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelAssignmentStatus.draft) }
    }
}
