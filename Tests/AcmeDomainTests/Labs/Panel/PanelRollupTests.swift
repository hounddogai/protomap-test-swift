@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelRollupTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelRollup("code-767", title: "title-789")
        #expect(item.status == Labs.PanelRollupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newPanelRollup("code-767", title: "title-789")
        try item.moveTo(Labs.PanelRollupStatus.rejected)
        #expect(item.status == Labs.PanelRollupStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelRollup("code-767", title: "title-789")
        item.status = Labs.PanelRollupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelRollupStatus.proposed) }
    }
}
