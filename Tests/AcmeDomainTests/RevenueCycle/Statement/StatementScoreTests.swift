@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementScoreTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newStatementScore("code-910", label: "label-947")
        #expect(item.status == RevenueCycle.StatementScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newStatementScore("code-910", label: "label-947")
        try item.moveTo(RevenueCycle.StatementScoreStatus.queued)
        #expect(item.status == RevenueCycle.StatementScoreStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newStatementScore("code-910", label: "label-947")
        item.status = RevenueCycle.StatementScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementScoreStatus.new) }
    }
}
