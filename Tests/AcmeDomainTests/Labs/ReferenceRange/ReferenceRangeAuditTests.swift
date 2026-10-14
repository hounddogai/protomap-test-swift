@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAuditTests {
    @Test func startsInDraft() throws {
        let item = Labs.newReferenceRangeAudit("code-656", name: "name-54")
        #expect(item.status == Labs.ReferenceRangeAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newReferenceRangeAudit("code-656", name: "name-54")
        try item.moveTo(Labs.ReferenceRangeAuditStatus.suspended)
        #expect(item.status == Labs.ReferenceRangeAuditStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newReferenceRangeAudit("code-656", name: "name-54")
        item.status = Labs.ReferenceRangeAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeAuditStatus.draft) }
    }
}
