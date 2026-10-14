@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelWindowTests {
    @Test func startsInNew() throws {
        let item = Labs.newCappedPanelWindow("code-439", title: "title-244")
        #expect(item.status == Labs.CappedPanelWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newCappedPanelWindow("code-439", title: "title-244")
        try item.moveTo(Labs.CappedPanelWindowStatus.queued)
        #expect(item.status == Labs.CappedPanelWindowStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newCappedPanelWindow("code-439", title: "title-244")
        item.status = Labs.CappedPanelWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedPanelWindowStatus.new) }
    }
}
