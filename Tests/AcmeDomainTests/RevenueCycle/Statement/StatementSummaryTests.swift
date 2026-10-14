@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSummaryTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newStatementSummary("code-527", name: "name-595")
        #expect(item.status == RevenueCycle.StatementSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newStatementSummary("code-527", name: "name-595")
        try item.moveTo(RevenueCycle.StatementSummaryStatus.pending)
        #expect(item.status == RevenueCycle.StatementSummaryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newStatementSummary("code-527", name: "name-595")
        item.status = RevenueCycle.StatementSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementSummaryStatus.draft) }
    }
}
