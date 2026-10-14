@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelTargetTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPanelTarget("code-368", title: "title-998")
        #expect(item.status == Labs.PanelTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newPanelTarget("code-368", title: "title-998")
        try item.moveTo(Labs.PanelTargetStatus.closed)
        #expect(item.status == Labs.PanelTargetStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPanelTarget("code-368", title: "title-998")
        item.status = Labs.PanelTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelTargetStatus.draft) }
    }
}
