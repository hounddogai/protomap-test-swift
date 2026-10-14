@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultResultAuditTests {
    @Test func startsInDraft() throws {
        let item = Labs.newDefaultResultAudit("code-726", title: "title-105")
        #expect(item.status == Labs.DefaultResultAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newDefaultResultAudit("code-726", title: "title-105")
        try item.moveTo(Labs.DefaultResultAuditStatus.active)
        #expect(item.status == Labs.DefaultResultAuditStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newDefaultResultAudit("code-726", title: "title-105")
        item.status = Labs.DefaultResultAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultResultAuditStatus.draft) }
    }
}
