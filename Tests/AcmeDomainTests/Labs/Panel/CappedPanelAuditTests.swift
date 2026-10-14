@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelAuditTests {
    @Test func startsInNew() throws {
        let item = Labs.newCappedPanelAudit("code-250", name: "name-817")
        #expect(item.status == Labs.CappedPanelAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newCappedPanelAudit("code-250", name: "name-817")
        try item.moveTo(Labs.CappedPanelAuditStatus.queued)
        #expect(item.status == Labs.CappedPanelAuditStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newCappedPanelAudit("code-250", name: "name-817")
        item.status = Labs.CappedPanelAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedPanelAuditStatus.new) }
    }
}
