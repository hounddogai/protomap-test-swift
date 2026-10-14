@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBaselineTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPanelBaseline("code-335", title: "title-574")
        #expect(item.status == Labs.PanelBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newPanelBaseline("code-335", title: "title-574")
        try item.moveTo(Labs.PanelBaselineStatus.pending)
        #expect(item.status == Labs.PanelBaselineStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPanelBaseline("code-335", title: "title-574")
        item.status = Labs.PanelBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelBaselineStatus.draft) }
    }
}
