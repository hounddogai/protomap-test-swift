@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAuditTests {
    @Test func startsInNew() throws {
        let item = Labs.newAccessionAudit("code-814", label: "label-881")
        #expect(item.status == Labs.AccessionAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newAccessionAudit("code-814", label: "label-881")
        try item.moveTo(Labs.AccessionAuditStatus.queued)
        #expect(item.status == Labs.AccessionAuditStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newAccessionAudit("code-814", label: "label-881")
        item.status = Labs.AccessionAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionAuditStatus.new) }
    }
}
