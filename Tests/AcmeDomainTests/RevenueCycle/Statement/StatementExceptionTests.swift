@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementExceptionTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newStatementException("code-664", label: "label-947")
        #expect(item.status == RevenueCycle.StatementExceptionStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newStatementException("code-664", label: "label-947")
        try item.moveTo(RevenueCycle.StatementExceptionStatus.pending)
        #expect(item.status == RevenueCycle.StatementExceptionStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newStatementException("code-664", label: "label-947")
        item.status = RevenueCycle.StatementExceptionStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementExceptionStatus.draft) }
    }
}
