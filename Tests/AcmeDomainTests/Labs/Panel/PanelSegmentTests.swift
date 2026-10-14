@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelSegmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPanelSegment("code-632", label: "label-144")
        #expect(item.status == Labs.PanelSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newPanelSegment("code-632", label: "label-144")
        try item.moveTo(Labs.PanelSegmentStatus.closed)
        #expect(item.status == Labs.PanelSegmentStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPanelSegment("code-632", label: "label-144")
        item.status = Labs.PanelSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelSegmentStatus.draft) }
    }
}
